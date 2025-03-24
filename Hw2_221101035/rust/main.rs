use std::collections::HashMap;
use std::io::{self, Write};

#[derive(Debug, Clone)]
enum Value {
    Number(i32),
    Undefined,
}

#[derive(Debug)]
enum Expr {
    Number(i32),
    Variable(String),
    Add(Box<Expr>, Box<Expr>),
    Sub(Box<Expr>, Box<Expr>),
    Mul(Box<Expr>, Box<Expr>),
    Div(Box<Expr>, Box<Expr>),
    Assign(String, Box<Expr>),
}

#[derive(Debug)]
struct Interpreter {
    variables: HashMap<String, i32>,
}

impl Interpreter {
    fn new() -> Self {
        Interpreter {
            variables: HashMap::new(),
        }
    }

    fn eval(&mut self, expr: Expr) -> Result<i32, String> {
        match expr {
            Expr::Number(n) => Ok(n),
            Expr::Variable(var) => self
                .variables
                .get(&var)
                .cloned()
                .ok_or_else(|| format!("Undefined variable: {}", var)),
            Expr::Add(left, right) => {
                let left_val = self.eval(*left)?;
                let right_val = self.eval(*right)?;
                Ok(left_val + right_val)
            }
            Expr::Sub(left, right) => {
                let left_val = self.eval(*left)?;
                let right_val = self.eval(*right)?;
                Ok(left_val - right_val)
            }
            Expr::Mul(left, right) => {
                let left_val = self.eval(*left)?;
                let right_val = self.eval(*right)?;
                Ok(left_val * right_val)
            }
            Expr::Div(left, right) => {
                let left_val = self.eval(*left)?;
                let right_val = self.eval(*right)?;
                if right_val == 0 {
                    Err("Error: Division by zero".to_string())
                } else {
                    Ok(left_val / right_val)
                }
            }
            Expr::Assign(var, expr) => {
                let value = self.eval(*expr)?;
                self.variables.insert(var, value);
                Ok(value)
            }
        }
    }
}

fn main() {
    let mut interpreter = Interpreter::new();

    loop {
        print!("Enter expression or 'q' to quit: ");
        io::stdout().flush().unwrap();

        let mut input = String::new();
        io::stdin().read_line(&mut input).unwrap();

        let input = input.trim();
        if input == "q" {
            break;
        }

        match parse_expr(input) {
            Ok(expr) => match interpreter.eval(expr) {
                Ok(result) => println!("Result: {}", result),
                Err(err) => println!("Error: {}", err),
            },
            Err(err) => println!("Parse Error: {}", err),
        }
    }
}

fn parse_expr(input: &str) -> Result<Expr, String> {
    let tokens = tokenize(input)?;
    parse_tokens(&tokens)
}

fn tokenize(input: &str) -> Result<Vec<String>, String> {
    let mut tokens = Vec::new();
    let mut current_token = String::new();

    for c in input.chars() {
        if c.is_whitespace() {
            if !current_token.is_empty() {
                tokens.push(current_token.clone());
                current_token.clear();
            }
        } else if c == '(' || c == ')' || "+-*/=()".contains(c) {
            if !current_token.is_empty() {
                tokens.push(current_token.clone());
                current_token.clear();
            }
            tokens.push(c.to_string());
        } else {
            current_token.push(c);
        }
    }
    if !current_token.is_empty() {
        tokens.push(current_token);
    }

    Ok(tokens)
}

fn parse_tokens(tokens: &[String]) -> Result<Expr, String> {
    let mut index = 0;
    parse_add_sub(tokens, &mut index)
}

fn parse_add_sub(tokens: &[String], index: &mut usize) -> Result<Expr, String> {
    let mut left = parse_mul_div(tokens, index)?;

    while *index < tokens.len() {
        let token = &tokens[*index];
        if token == "+" || token == "-" {
            *index += 1;
            let right = parse_mul_div(tokens, index)?;
            left = if token == "+" {
                Expr::Add(Box::new(left), Box::new(right))
            } 
else {
                Expr::Sub(Box::new(left), Box::new(right))
            };
        } else {
            break;
        }
    }

    Ok(left)
}

fn parse_mul_div(tokens: &[String], index: &mut usize) -> Result<Expr, String> {
    let mut left = parse_factor(tokens, index)?;

    while *index < tokens.len() {
        let token = &tokens[*index];
        if token == "*" || token == "/" {
            *index += 1;
            let right = parse_factor(tokens, index)?;
            left = if token == "*" {
                Expr::Mul(Box::new(left), Box::new(right))
            } else {
                Expr::Div(Box::new(left), Box::new(right))
            };
        } else {
            break;
        }
    }

    Ok(left)
}

fn parse_factor(tokens: &[String], index: &mut usize) -> Result<Expr, String> {
    let token = &tokens[*index];
    *index += 1;

    if token == "(" {
        let mut open_paren_count = 1;

        let expr = parse_add_sub(tokens, index)?;

        while *index < tokens.len() && tokens[*index] == ")" {
            open_paren_count -= 1;
            *index += 1;
        }

        if open_paren_count > 0 {
            return Err("Error: Mismatched parentheses, expected closing parenthesis".to_string());
        }

        Ok(expr)
    } 
else if let Ok(num) = token.parse::<i32>() 
{
        Ok(Expr::Number(num))
    } 
else if token.chars().all(|c| c.is_alphanumeric()) 
{
        Ok(Expr::Variable(token.clone()))
    } 
else 
{
        Err(format!("Unexpected token: {}", token))
    }
}
