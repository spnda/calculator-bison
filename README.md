# calculator

A simple calculator I wrote as a school project using Bison and Java. The provided Makefile requires `bison` and `javac` to be in the PATH. To run the project, do this:

```
make
make run
```

The calculator now awaits input and will always output the result on a new line prefixed with `>`. The calculator generally makes use of `BigDecimal` to hold generic decimals, but has to convert to floating point numbers for calculating logiarithms or square roots. Some examples of how to use the calculator can be found below.

Basic arithmetic:
```
5 * 5 + 5
> 30
```
```
sqrt(4)^2
4
```

Using functions:
```
cos(pi)
> -1
```
```
e^ln(100)
> 100
```

Assigning and using variables:
```
A = 500
> A = 500
```
```
A / 20
> 25
```
