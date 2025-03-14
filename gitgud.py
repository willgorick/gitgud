
import sys
from typing import List
from readchar import readkey, key
import subprocess

VALID_PARAMS = ["commit", "pr"]
TYPE_PROMPT = "What type of change are you committing: "
SCOPE_PROMPT = "What is the scope of this change (press [enter] to skip): "
DESCRIPTION_PROMPT = "Short imperative description explaining what changed: "
COLOR = "\033[96m"
CLEAR = "\033[0m"


def main():
    if len(sys.argv) < 2:
        print(
            f"No params provided, please provide one of the following: {COLOR}{VALID_PARAMS}{CLEAR}")
        return 0
    if len(sys.argv) > 2:
        print("Too many params provided")
        return 0

    command = sys.argv[1]
    if command == "commit":
        commit()
    elif command == "pr":
        pr()


def commit():
    type = _get_commit_type()
    scope = _get_commit_scope()
    description = _get_commit_description()
    commit_message = _format_commit_message(type, scope, description)
    print(f"Commit message: {COLOR}{commit_message}{CLEAR}")
    print("Do you want to commit this message?: (y/n): ")
    while True:
        k = readkey()
        if k == "y":
            print("Committing...")
            subprocess.run(["git", "commit", "-m" f"{commit_message}"])
            break
        if k == "n":
            print("Exiting...")
            break


def pr():
    print("pr")


def choose_from_menu(prompt: str, options: List):
    total_rows, total_rows_with_prompt = len(options), len(options)+1
    curr = 0
    selection = None
    print(prompt)
    while selection == None:
        # output all options and which is currently selected
        for i in range(total_rows):
            if i == curr:
                print(f"{COLOR}[x] {options[i]}{CLEAR}")
            else:
                print(f"[]  {options[i]}")

        # read input
        k = readkey()
        if k == key.UP:
            curr -= 1
            curr %= total_rows
        elif k == key.DOWN:
            curr += 1
            curr %= total_rows
        elif k == key.ENTER:
            selection = options[curr]
            break

        # clear options from screen
        for _ in range(total_rows):
            print("\033[2k\r", end="")
            print("\033[F", end="")

    for _ in range(total_rows_with_prompt):
        print("\033[A\033[K", end="")
    return selection


def _get_commit_type():
    options = [
        "feat",
        "fix",
        "docs",
        "style",
        "test"
    ]

    type = choose_from_menu(TYPE_PROMPT, options)
    print(f"{TYPE_PROMPT}{COLOR}{type}{CLEAR}")
    return type


def _get_commit_scope():
    scope = input(f"{SCOPE_PROMPT}")
    print("\033[A\033[K", end="")
    print(f"{SCOPE_PROMPT}{COLOR}{scope}{CLEAR}")
    return scope


def _get_commit_description():
    description = input(f"{DESCRIPTION_PROMPT}")
    print("\033[A\033[K", end="")
    print(f"{DESCRIPTION_PROMPT}{COLOR}{description}{CLEAR}")
    return description


def _format_commit_message(type, scope, description):
    if scope:
        scope = f"({scope})"
    return f"{type}{scope}: {description}"


if __name__ == "__main__":
    main()
