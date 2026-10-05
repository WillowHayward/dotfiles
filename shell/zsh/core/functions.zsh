# Functions available on every profile live in core/functions/ and are loaded
# here; dev-only functions live in dev/functions/ and are loaded by .zshrc.
for whc_function_file in "${${(%):-%x}:A:h}"/functions/*.zsh(N); do
    source "$whc_function_file"
done
unset whc_function_file
