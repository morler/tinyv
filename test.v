module test

pub struct Time {
    hour int
    minute int
}

pub struct Person {
    Time // Embedding at the beginning
    name string
    age int
    mut:
        value string = 'default'
}