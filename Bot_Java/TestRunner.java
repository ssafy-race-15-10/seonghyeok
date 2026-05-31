public class TestRunner {
    public static void main(String[] args) {
        System.out.println("TestRunner ready. Add test calls here.");
    }

    static void assertTrue(boolean condition, String message) {
        if (!condition) throw new AssertionError("FAIL: " + message);
    }
}
