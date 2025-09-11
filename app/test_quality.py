def bad_function():
    x = 1 + 2
    print(
        "This line is way too long and should trigger flake8 because it exceeds the maximum line length configured"
    )
    return x
