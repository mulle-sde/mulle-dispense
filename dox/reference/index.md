# mulle-dispense Command Reference

## Overview

**mulle-dispense** is a command-line tool for distributing build product files in a uniform fashion. It copies files from a source directory to a destination directory, possibly reorganizing them on the fly to create proper package structures with headers, libraries, executables, and other build artifacts placed in appropriate subdirectories.

## Command Categories

### Core Operations
- **[`copy`](copy.md)** - Copy files from srcdir to dstdir, reorganizing as needed (default)

### Utility Commands
- **[`libexec-dir`](libexec-dir.md)** - Print path to mulle-dispense libexec
- **[`uname`](uname.md)** - mulle-dispense's simplified uname(1)
- **[`version`](version.md)** - Print mulle-dispense version

## Quick Start Examples

### Basic File Distribution
```bash
# Copy build products from build directory to package directory
mulle-dispense copy build /tmp/package

# Copy with custom header directory
mulle-dispense copy --header-dir include build /tmp/package

# Move instead of copy
mulle-dispense copy --move build /tmp/package
```

### Advanced Distribution
```bash
# Distribute only headers
mulle-dispense copy --only-headers build /tmp/package

# Lift headers from subdirectories
mulle-dispense copy --lift-headers build /tmp/package

# Custom project name for logging
mulle-dispense copy --name MyProject build /tmp/package
```

## Command Reference Table

| Command | Category | Description |
|---------|----------|-------------|
| `copy` | Core | Copy files from srcdir to dstdir, reorganizing as needed (default) |
| `libexec-dir` | Utility | Print path to mulle-dispense libexec |
| `uname` | Utility | mulle-dispense's simplified uname(1) |
| `version` | Utility | Print mulle-dispense version |

## Getting Help

### Command Help
```bash
# Get help for a specific command
mulle-dispense copy --help

# List all available commands
mulle-dispense --help

# Get detailed command information
mulle-dispense copy --help --verbose
```

### Documentation
- Each command has a dedicated documentation file in this reference
- Use `--help` for quick command usage
- Check source code analysis for implementation details

## Common Workflows

### Basic Package Creation
1. **Build** your project: `make` or `cmake --build build`
2. **Distribute** files: `mulle-dispense copy build /tmp/package`
3. **Verify** structure: `find /tmp/package -type f | head -20`

### Header Management
1. **Copy** with header lifting: `mulle-dispense copy --lift-headers build /tmp/package`
2. **Set** custom header directory: `mulle-dispense copy --header-dir include build /tmp/package`
3. **Check** header placement: `find /tmp/package -name "*.h"`

### Library Distribution
1. **Include** libraries: `mulle-dispense copy --libraries build /tmp/package`
2. **Add** pkgconfig files: Ensure pkgconfig files are in build/lib/pkgconfig/
3. **Verify** library links: `find /tmp/package -name "*.a" -o -name "*.so"`

## Troubleshooting

### Common Issues
```bash
# Check source directory contents
ls -la build/

# Verify destination permissions
ls -ld /tmp/package

# Test with verbose output
mulle-dispense copy --verbose build /tmp/package
```

### File Organization Problems
```bash
# Check what files are being processed
mulle-dispense copy --ls build /tmp/package

# Verify file types are detected correctly
find build -type f | head -10

# Check for symlinks or special files
find build -type l
```

### Permission Issues
```bash
# Ensure write permissions on destination
chmod -R u+w /tmp/package

# Check source file permissions
find build ! -readable

# Use force option if needed
mulle-dispense copy --force build /tmp/package
```

## Advanced Usage

### Custom File Mapping
```bash
# Use custom mapper script
echo '#!/bin/sh
case "$1" in
  *.h) echo "include/$1" ;;
  *) echo "$1" ;;
esac' > mapper.sh
chmod +x mapper.sh
mulle-dispense copy --mapper-file mapper.sh build /tmp/package
```

### Selective Distribution
```bash
# Only distribute headers
mulle-dispense copy --only-headers build /tmp/package

# Exclude resources
mulle-dispense copy --no-resources build /tmp/package

# Custom executable handling
mulle-dispense copy --executables build /tmp/package
```

### Integration with Build Systems
```bash
# Use with cmake install
cmake --install build --prefix /tmp/staging
mulle-dispense copy /tmp/staging /tmp/package

# Combine with make install
make install DESTDIR=/tmp/staging
mulle-dispense copy /tmp/staging /tmp/package
```

## Command Categories and Priorities

### High Priority Commands (Document First)
- Core Operations commands (`copy`)
- System information (`libexec-dir`, `uname`)
- Configuration commands (`version`)

### Medium Priority Commands
- Advanced processing options
- Integration features
- Utility commands

### Low Priority Commands
- Experimental or advanced features
- Platform-specific operations
- Hidden/utility commands

## Maintenance Guidelines

### Regular Updates
- Review documentation quarterly
- Update for new command options
- Refresh examples and workflows
- Verify cross-references remain valid

### Change Management
- Document breaking changes immediately
- Update affected cross-references
- Maintain change history
- Communicate updates to users

### Quality Metrics
- All commands have documentation
- Examples are tested and working
- Troubleshooting covers 80% of issues
- Documentation is updated within 1 week of changes

## Process Checklist

### Pre-Documentation
- [ ] **MANDATORY: Read the main script file** (`mulle-dispense/mulle-dispense`) and examine the `dispense::main()` function's case statement
- [ ] **MANDATORY: Document EVERY command** found in the case statement - do not skip any, even if they seem like internal utilities
- [ ] **MANDATORY: Verify command count** - Cross-reference with the `commands` case output to ensure completeness
- [ ] **MANDATORY: Analyze command source code** - Do not rely on help output or assumptions
- [ ] Test command with all options
- [ ] Identify related commands
- [ ] Gather error scenarios

### Documentation Creation
- [ ] Write header and quick start
- [ ] Document all options comprehensively
- [ ] Create practical examples
- [ ] Add troubleshooting section
- [ ] Include integration examples

### Quality Assurance
- [ ] Test all examples
- [ ] Verify option documentation
- [ ] Check cross-references
- [ ] Validate troubleshooting steps
- [ ] Review for completeness

### Final Steps
- [ ] Format consistently
- [ ] Update index if needed
- [ ] Commit with clear message
- [ ] Update related documentation

## Command Testing Results

### Comprehensive Command Checklist

#### [Core Operations]
- [ ] `mulle-dispense copy <args>` : Copy files from srcdir to dstdir, reorganizing as needed

#### [System & Info]
- [ ] `mulle-dispense libexec-dir <args>` : Print path to mulle-dispense libexec
- [ ] `mulle-dispense uname <args>` : mulle-dispense's simplified uname(1)
- [ ] `mulle-dispense version <args>` : Print mulle-dispense version

### Summary
- **Working Commands**: 0 commands tested (new session)
- **Failing Commands**: 0 commands tested (new session)
- **Not Found Commands**: 0 commands tested (new session)
- **Untested Commands**: All commands available but not yet tested

### Notes
- This is a new documentation session for mulle-dispense
- Need to analyze the actual command structure and available options
- Commands may differ significantly from other tools
- Will need to test each command to verify syntax and behavior
- Documentation structure follows the same pattern as other tools for consistency

## Success Metrics

### Documentation Quality
- **Coverage**: 100% of commands documented
- **Accuracy**: 95% of examples work as written
- **Completeness**: All options and error conditions covered
- **Usability**: New users can accomplish tasks independently

### User Experience
- **Findability**: Users can locate needed information quickly
- **Clarity**: Documentation is understandable without prior knowledge
- **Actionability**: Examples provide clear, runnable solutions
- **Reliability**: Information remains accurate over time

### Maintenance Efficiency
- **Update Speed**: Documentation updated within 1 week of changes
- **Review Cycle**: Quarterly comprehensive review completed
- **Error Rate**: Less than 5% of documentation contains errors
- **Consistency**: 100% adherence to formatting standards

## Related Documentation

- **[TODO.md](TODO.md)** - Current development status and process guide
- **[README.md](../../README.md)** - Project overview and installation
- **[mulle-sde.md](../mulle-sde.md)** - Build system guidelines
- **[mulle-fetch.md](../mulle-fetch.md)** - Fetching and cloning documentation