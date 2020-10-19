# akkeris-tools

A collection of scripts that can be helpful when developing and troubleshooting Akkeris.

## Installation

```bash
$ ./install.sh
```

## Development

To build the latest version of the script templates in the `templates` directory, run `./build.sh`. Please note that if using MacOS, `gnu-sed` is required (`brew install gnu-sed`).

## Writing Scripts

We use [argbash](https://argbash.io/) to make parameter parsing easy. See the [argbash documentation](https://argbash.readthedocs.io/en/latest/) for detailed usage, or check out the quick tutorial below.

### Using Argbash

You can install argbash, but it's easiest to use it via Docker. The following script will create the `argbash-docker` and `argbash-init-docker` commands for easier usage via the command line:

```bash
printf '%s\n' '#!/bin/bash' 'docker run --rm -v "$(pwd):/work" -u "$(id -u):$(id -g)" matejak/argbash "$@"' > argbash-docker
printf '%s\n' '#!/bin/bash' 'docker run --rm -e PROGRAM=argbash-init -v "$(pwd):/work" -u "$(id -u):$(id -g)" matejak/argbash "$@"' > argbash-init-docker
chmod a+x argbash-docker argbash-init-docker
```

### Creating an Argbash Template

To start, you can use `argbash-init-docker` to create a new template. The following command will create a template with the `merp` positional argument and the `derp` optional argument:

```
argbash-init-docker --pos merp --opt derp merpderp-template.sh
```

The generated template will look like the following:

```
#!/bin/bash

# m4_ignore(
echo "This is just a script template, not the script (yet) - pass it to 'argbash' to fix this." >&2
exit 11  #)Created by argbash-init v2.10.0
# ARG_OPTIONAL_SINGLE([derp])
# ARG_POSITIONAL_SINGLE([merp])
# ARG_DEFAULTS_POS
# ARG_HELP([<The general help message of my script>])
# ARGBASH_GO

# [ <-- needed because of Argbash

# vvv  PLACE YOUR CODE HERE  vvv
# For example:
printf 'Value of --%s: %s\n' 'derp' "$_arg_derp"
printf "Value of '%s': %s\\n" 'merp' "$_arg_merp"

# ^^^  TERMINATE YOUR CODE BEFORE THE BOTTOM ARGBASH MARKER  ^^^

# ] <-- needed because of Argbash
```

The header of the file is where all of the argbash directives are located. Any arguments to the `argbash` macros need to be enclosed in brackets. 

Now, we'll need to make a few changes to our template. We can add help text and argument descriptions, and add our script body inbetween the `argbash` markers:

```
#!/bin/bash

# m4_ignore(
echo "This is just a script template, not the script (yet) - pass it to 'argbash' to fix this." >&2
exit 11  #)Created by argbash-init v2.10.0
# ARG_OPTIONAL_SINGLE([derp], [d], [A description of the 'd' option goes here], [foo])
# ARG_POSITIONAL_SINGLE([merp], [A description of the positional argument goes here])
# ARG_DEFAULTS_POS
# ARG_HELP([The script help message would go here])
# ARGBASH_GO

# [ <-- needed because of Argbash

echo "$_arg_derp"
echo "$_arg_merp"

# ] <-- needed because of Argbash
```

Now, we can generate the script with `argbash` from the template:

`$ argbash merpderp-template.sh -o merpderp.sh`

Run it and see what happens!

```
$ ./merpderp.sh --help
The script help message would go here
Usage: ./merpderp.sh [-d|--derp <arg>] [-h|--help] <merp>
	<merp>: A description of the positional argument goes here
	-d, --derp: A description of the 'd' option goes here (default: 'foo')
	-h, --help: Prints help
```

```
$ ./merpderp.sh positional -d option
option
positional
```

### Helper Functions

The functions `red`, `green`, `yellow`, and `reset` will be injected into built scripts. They help color stdout text so you don't have to remember the command every time. Here's an example of how you use them:

```
echo -e "\n${red}✗${reset} No pods matching \"$name\" found in the \"$ns\" namespace."
```