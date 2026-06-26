#!/usr/bin/env python3
"""Probe an AirSim MessagePack-RPC server without third-party packages."""

from __future__ import annotations

import argparse
import socket
import struct
import sys
from typing import Any


REQUEST = 0
RESPONSE = 1


class MsgpackError(ValueError):
    pass


def pack(value: Any) -> bytes:
    if value is None:
        return b"\xc0"
    if value is False:
        return b"\xc2"
    if value is True:
        return b"\xc3"
    if isinstance(value, int):
        if 0 <= value <= 0x7F:
            return bytes([value])
        if -32 <= value < 0:
            return bytes([0xE0 | (value + 32)])
        if 0 <= value <= 0xFF:
            return b"\xcc" + struct.pack(">B", value)
        if 0 <= value <= 0xFFFF:
            return b"\xcd" + struct.pack(">H", value)
        if 0 <= value <= 0xFFFFFFFF:
            return b"\xce" + struct.pack(">I", value)
        if -0x80000000 <= value <= 0x7FFFFFFF:
            return b"\xd2" + struct.pack(">i", value)
        return b"\xd3" + struct.pack(">q", value)
    if isinstance(value, float):
        return b"\xcb" + struct.pack(">d", value)
    if isinstance(value, str):
        raw = value.encode("utf-8")
        size = len(raw)
        if size <= 31:
            return bytes([0xA0 | size]) + raw
        if size <= 0xFF:
            return b"\xd9" + struct.pack(">B", size) + raw
        if size <= 0xFFFF:
            return b"\xda" + struct.pack(">H", size) + raw
        return b"\xdb" + struct.pack(">I", size) + raw
    if isinstance(value, (list, tuple)):
        size = len(value)
        if size <= 15:
            prefix = bytes([0x90 | size])
        elif size <= 0xFFFF:
            prefix = b"\xdc" + struct.pack(">H", size)
        else:
            prefix = b"\xdd" + struct.pack(">I", size)
        return prefix + b"".join(pack(item) for item in value)
    if isinstance(value, dict):
        size = len(value)
        if size <= 15:
            prefix = bytes([0x80 | size])
        elif size <= 0xFFFF:
            prefix = b"\xde" + struct.pack(">H", size)
        else:
            prefix = b"\xdf" + struct.pack(">I", size)
        return prefix + b"".join(pack(key) + pack(item) for key, item in value.items())
    raise TypeError(f"unsupported value for msgpack: {type(value).__name__}")


def read_exact(sock: socket.socket, size: int) -> bytes:
    chunks = []
    remaining = size
    while remaining:
        chunk = sock.recv(remaining)
        if not chunk:
            raise ConnectionError("connection closed while waiting for response")
        chunks.append(chunk)
        remaining -= len(chunk)
    return b"".join(chunks)


def unpack_one(data: bytes, offset: int = 0) -> tuple[Any, int]:
    if offset >= len(data):
        raise MsgpackError("unexpected end of data")

    marker = data[offset]
    offset += 1

    if marker <= 0x7F:
        return marker, offset
    if marker >= 0xE0:
        return marker - 0x100, offset
    if 0x80 <= marker <= 0x8F:
        return unpack_map(data, offset, marker & 0x0F)
    if 0x90 <= marker <= 0x9F:
        return unpack_array(data, offset, marker & 0x0F)
    if 0xA0 <= marker <= 0xBF:
        return unpack_string(data, offset, marker & 0x1F)
    if marker == 0xC0:
        return None, offset
    if marker == 0xC2:
        return False, offset
    if marker == 0xC3:
        return True, offset
    if marker == 0xCC:
        return read_struct(data, offset, ">B")
    if marker == 0xCD:
        return read_struct(data, offset, ">H")
    if marker == 0xCE:
        return read_struct(data, offset, ">I")
    if marker == 0xCF:
        return read_struct(data, offset, ">Q")
    if marker == 0xD0:
        return read_struct(data, offset, ">b")
    if marker == 0xD1:
        return read_struct(data, offset, ">h")
    if marker == 0xD2:
        return read_struct(data, offset, ">i")
    if marker == 0xD3:
        return read_struct(data, offset, ">q")
    if marker == 0xCA:
        return read_struct(data, offset, ">f")
    if marker == 0xCB:
        return read_struct(data, offset, ">d")
    if marker == 0xD9:
        size, offset = read_struct(data, offset, ">B")
        return unpack_string(data, offset, size)
    if marker == 0xDA:
        size, offset = read_struct(data, offset, ">H")
        return unpack_string(data, offset, size)
    if marker == 0xDB:
        size, offset = read_struct(data, offset, ">I")
        return unpack_string(data, offset, size)
    if marker == 0xDC:
        size, offset = read_struct(data, offset, ">H")
        return unpack_array(data, offset, size)
    if marker == 0xDD:
        size, offset = read_struct(data, offset, ">I")
        return unpack_array(data, offset, size)
    if marker == 0xDE:
        size, offset = read_struct(data, offset, ">H")
        return unpack_map(data, offset, size)
    if marker == 0xDF:
        size, offset = read_struct(data, offset, ">I")
        return unpack_map(data, offset, size)

    raise MsgpackError(f"unsupported msgpack marker: 0x{marker:02x}")


def read_struct(data: bytes, offset: int, fmt: str) -> tuple[Any, int]:
    size = struct.calcsize(fmt)
    if offset + size > len(data):
        raise MsgpackError("unexpected end of data")
    return struct.unpack(fmt, data[offset : offset + size])[0], offset + size


def unpack_string(data: bytes, offset: int, size: int) -> tuple[str, int]:
    if offset + size > len(data):
        raise MsgpackError("unexpected end of data")
    return data[offset : offset + size].decode("utf-8", errors="replace"), offset + size


def unpack_array(data: bytes, offset: int, size: int) -> tuple[list[Any], int]:
    values = []
    for _ in range(size):
        value, offset = unpack_one(data, offset)
        values.append(value)
    return values, offset


def unpack_map(data: bytes, offset: int, size: int) -> tuple[dict[Any, Any], int]:
    values = {}
    for _ in range(size):
        key, offset = unpack_one(data, offset)
        value, offset = unpack_one(data, offset)
        values[key] = value
    return values, offset


def rpc_call(host: str, port: int, method: str, args: list[Any], timeout: float) -> Any:
    request = pack([REQUEST, 1, method, args])

    with socket.create_connection((host, port), timeout=timeout) as sock:
        sock.settimeout(timeout)
        sock.sendall(request)
        first = read_exact(sock, 1)

        # MessagePack-RPC replies are complete MessagePack objects. For the
        # AirSim probe calls used here, the first byte is a fixed array header.
        if first[0] & 0xF0 != 0x90:
            raise MsgpackError(f"unexpected response header: 0x{first[0]:02x}")

        array_size = first[0] & 0x0F
        if array_size != 4:
            raise MsgpackError(f"unexpected RPC response array size: {array_size}")

        # Read incrementally until a full response object can be decoded.
        payload = bytearray(first)
        while True:
            try:
                response, offset = unpack_one(bytes(payload))
                if offset == len(payload):
                    break
            except MsgpackError:
                pass
            payload.extend(read_exact(sock, 1))

        msg_type, msg_id, error, result = response
        if msg_type != RESPONSE or msg_id != 1:
            raise MsgpackError(f"unexpected RPC envelope: {response!r}")
        if error is not None:
            raise RuntimeError(f"RPC error from {method}: {error!r}")
        return result


def main() -> int:
    parser = argparse.ArgumentParser(description="Probe an AirSim RPC endpoint.")
    parser.add_argument("host", help="Windows host IP or DNS name running the simulator")
    parser.add_argument("--port", type=int, default=41451, help="AirSim RPC port")
    parser.add_argument("--timeout", type=float, default=3.0, help="socket timeout seconds")
    args = parser.parse_args()

    checks = [
        ("getServerVersion", []),
        ("getMinRequiredClientVersion", []),
    ]

    for method, method_args in checks:
        try:
            result = rpc_call(args.host, args.port, method, method_args, args.timeout)
        except Exception as exc:
            print(f"FAIL {method}: {exc}", file=sys.stderr)
            return 1
        print(f"OK {method}: {result!r}")

    print(f"AirSim RPC endpoint responded at {args.host}:{args.port}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
