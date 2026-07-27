#!/usr/bin/env python3
# Generate a dependency-free rustc PGO training corpus.
import os
import sys

out = sys.argv[1]
os.makedirs(out, exist_ok=True)


def write(name, body):
    with open(os.path.join(out, name), "w") as f:
        f.write("#![allow(dead_code, unused)]\n")
        f.write(body)


generics = ["use std::collections::HashMap;\n"]
for i in range(120):
    generics.append(f"""
fn reduce_{i}<T: Copy + Into<i64> + Ord>(xs: &[T]) -> i64 {{
    let mut m: HashMap<i64, i64> = HashMap::new();
    for &x in xs {{ let v: i64 = x.into(); *m.entry(v % {i % 11 + 1}).or_insert(0) += v.wrapping_mul({i + 1}); }}
    let s: i64 = xs.iter().map(|&x| {{ let v: i64 = x.into(); v.wrapping_mul(v) }})
        .filter(|v| v % {i % 5 + 2} == 0).take(500).sum();
    m.values().copied().fold(s, |a, b| a.wrapping_add(b))
}}""")
generics.append("\npub fn run_generics() -> i64 {")
generics.append("    let a: Vec<i32> = (0..800).collect();")
generics.append("    let b: Vec<i16> = (0..800).map(|x| (x % 97) as i16).collect();")
generics.append("    let mut t = 0i64;")
for i in range(120):
    generics.append(f"    t = t.wrapping_add(reduce_{i}(&a)).wrapping_add(reduce_{i}(&b));")
generics.append("    t\n}\n")
write("generics.rs", "\n".join(generics))


traits = ["pub trait Shape { fn area(&self) -> f64; fn name(&self) -> &'static str; }\n"]
for i in range(60):
    traits.append(f"""
pub struct S{i} {{ a: f64, b: f64 }}
impl Shape for S{i} {{
    fn area(&self) -> f64 {{ (self.a * {i + 1} as f64 + self.b).abs().sqrt() }}
    fn name(&self) -> &'static str {{ "s{i}" }}
}}""")
traits.append("\n#[derive(Clone)]\npub enum Op { Add(i64), Mul(i64), Neg, Sq, Mod(i64) }\n")
traits.append("""
pub fn apply(op: &Op, x: i64) -> i64 {
    match op {
        Op::Add(n) => x.wrapping_add(*n),
        Op::Mul(n) => x.wrapping_mul(*n),
        Op::Neg => x.wrapping_neg(),
        Op::Sq => x.wrapping_mul(x),
        Op::Mod(n) if *n != 0 => x % *n,
        Op::Mod(_) => 0,
    }
}
pub fn run_traits() -> f64 {
    let shapes: Vec<Box<dyn Shape>> = vec![
""")
for i in range(60):
    traits.append(f"        Box::new(S{i} {{ a: {i} as f64, b: {(i * 7) % 13} as f64 }}),")
traits.append("    ];")
traits.append("    let ops = [Op::Add(3), Op::Mul(2), Op::Neg, Op::Sq, Op::Mod(7)];")
traits.append("    let mut acc = 0.0;")
traits.append("    for s in &shapes { acc += s.area(); }")
traits.append("    let mut n = 1i64;")
traits.append("    for o in &ops { for _ in 0..1000 { n = apply(o, n).wrapping_add(1); } }")
traits.append("    acc + n as f64\n}\n")
write("traits.rs", "\n".join(traits))


macros = ["""
macro_rules! tuple_sum {
    ($($x:expr),*) => { 0i64 $(+ $x as i64)* };
}
fn fib(n: u64) -> u64 { if n < 2 { n } else { fib(n - 1).wrapping_add(fib(n - 2)) } }
fn ack(m: u64, n: u64) -> u64 {
    if m == 0 { n + 1 } else if n == 0 { ack(m - 1, 1) } else { ack(m - 1, ack(m, n - 1)) }
}
#[derive(Clone)]
struct Tree<T> { val: T, kids: Vec<Tree<T>> }
fn depth<T>(t: &Tree<T>) -> usize { 1 + t.kids.iter().map(depth).max().unwrap_or(0) }
fn build(d: usize) -> Tree<i64> {
    if d == 0 { Tree { val: 1, kids: vec![] } }
    else { Tree { val: d as i64, kids: vec![build(d - 1), build(d - 1)] } }
}
"""]
for i in range(80):
    macros.append(f"fn m_{i}() -> i64 {{ tuple_sum!({i}, {i*2}, {i*3}, {i%7}, {i%5}) }}")
macros.append("\npub fn run_macros() -> u64 {")
macros.append("    let mut s = fib(22).wrapping_add(ack(2, 7));")
macros.append("    let t = build(12); s = s.wrapping_add(depth(&t) as u64);")
for i in range(80):
    macros.append(f"    s = s.wrapping_add(m_{i}() as u64);")
macros.append("    s\n}\n")
write("macros.rs", "\n".join(macros))

print(f"wrote training corpus to {out}: " + ", ".join(sorted(os.listdir(out))))
