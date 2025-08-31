// Operator precedence verification test
module test_precedence

fn test_expressions() {
    // Test operator precedence: 2 + 3 * 4 should be 2 + (3 * 4) = 14, not (2 + 3) * 4 = 20
    a := 2 + 3 * 4  // This should be parsed as 2 + (3 * 4)

    // Test logical operator precedence: a && b || c should be (a && b) || c
    b := true
    c := false
    result := b && b || c  // Should be true

    // Test comparison precedence: a + b > c should be (a + b) > c
    compare := 1 + 2 > 3   // Should be true
}