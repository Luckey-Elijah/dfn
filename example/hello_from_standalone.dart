import 'dart:io';

void main(List<String> args) {
  stdout.writeln('Hello from standalone file!');
  assert(args.isNotEmpty, 'must provide some arguments');
}
