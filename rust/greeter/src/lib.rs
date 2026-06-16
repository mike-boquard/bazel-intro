pub fn hello(name: &str) -> String {
    format!("Hello, {}!", name)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn hello_with_name() {
        assert_eq!(hello("World"), "Hello, World!");
    }

    #[test]
    fn hello_with_empty_string() {
        assert_eq!(hello(""), "Hello, !");
    }

    #[test]
    fn hello_with_unicode() {
        assert_eq!(hello("日本語"), "Hello, 日本語!");
    }
}
