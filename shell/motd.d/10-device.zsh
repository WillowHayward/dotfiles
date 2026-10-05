# The machine's name, in the same red as the prompt prefix.
print -P "%B%K{#FF1F1F}%F{#FFFFFF}  ${WHC_DEVICE:-${HOST%%.*}}  %f%k%b  %F{#6272A4}${WHC_PROFILE:-unknown} profile%f"
