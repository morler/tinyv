// Simple SSA conversion test
fn test_simple() int {
    x := 3 + 4
    y := x * 2
    if y > 5 {
        z := y - 1
        return z
    } else {
        return 0
    }
}