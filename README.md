# advent2015

Advent of code 2015 solutions
 * build with `zig build`
 * run with `zig build run -- ARGS`

to run a specific solution run `advent2015 DAY`, where `DAY` is an
integer between 1 and 25 inclusive.

## project generation

re-generate missing files, or generate files for another Advent of Code event with
`zig build generate -Dyear=YEAR -Drepo=LINK -Dcopyright=CPYRT`, all you need is the `build.zig` file.
 * where `YEAR` is the event year
 * where `LINK` is a repo link to include in banner comments
 * where `CPYRT` is a copyright notice to include in banner comments

note, input files are not automatically populated
