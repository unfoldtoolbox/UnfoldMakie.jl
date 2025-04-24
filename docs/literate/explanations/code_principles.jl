# # Clear Code  

# 1. Code should be clear and concise.  
# 2. Variables in the code should have meaningful names.  
# 3. Function naming should follow established theories and naming conventions.  
# 4. Avoid functions longer than 50 lines to improve code readability.  
# 4.1. Write modular code by breaking complex tasks into smaller, reusable functions.  
# 4.2. Avoid deep nesting of loops and conditionals.  
# 5. Avoid putting more than 5 functions in a single file.  
# 6. Avoid pull requests that affect more than 10 files.  
# 7. Maintain consistent indentation and formatting across all files. Enforce it with linters (e.g., JuliaFormatter).  
# 8. Write meaningful commit messages that explain what changed and why (e.g., "Refactored plot function for better readability" instead of "fix").  
# 9. Minimize external dependencies. Only use external libraries when necessary to avoid compatibility issues and to reduce installation and loading time.  

# # Backward Compatibility  

# Backward compatibility means that newer versions of your software should work with old code written for older versions without major changes.  

# 1. Provide a clear changelog for new versions, detailing new features, fixes, and potential breaking changes.  
# 2. Avoid breaking changes whenever possible.  
# 3. Ensure consistent output formats. If your function previously returned a dictionary, avoid switching it to a list unless necessary.  
# 4. Use deprecation warnings. If a feature will be removed in future versions, notify users with warnings instead of immediately breaking their code.  
# 5. Use versioned documentation. Keep documentation for previous versions accessible so users with older codebases can still find relevant information.  
# 6. Avoid removing or renaming functions or their arguments. If you must remove a function or its argument, keep the old name as an alias or mark it as deprecated before removal.  
# 7. Write unit tests to prevent unexpected behavior whenever you add new features.  

# # User-Friendliness  

# 1. Every function exposed to the user should have docstrings specifying all parameters, their types, and input/output arguments.  
# 2. Ensure the documentation includes visual and code examples where applicable, especially if the figure is commonly used and/or complex.  
# 3. Users should have the ability to customize all parts of the figure.  
# 4. Most users will not check the default settings, so it is important to encourage them to label key details of the figure.  
# 5. Comment the code, especially if the code is not self-explanatory. But don't overuse it.  
# 6. Provide meaningful error messages that guide users toward solutions.  
# 7. Test the usability of your code with non-expert users to identify pain points.  

# Written by **Vladimir Mikheev**  
