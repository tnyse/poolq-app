# PoolQ App - Cursor Development Rules

## Project Structure
- All Flutter code must be organized in the `lib` directory following the established structure:
  - `screens/`: UI screens and pages
  - `widgets/`: Reusable UI components
  - `providers/`: State management using Provider
  - `services/`: Business logic and external service integrations
  - `models/`: Data models and entities
  - `constants/`: Application-wide constants and configurations

## Code Organization
1. **File Naming**
   - Use snake_case for file names (e.g., `user_profile_screen.dart`)
   - Widget files should end with their type (e.g., `_screen.dart`, `_widget.dart`)
   - Provider files should end with `_provider.dart`
   - Service files should end with `_service.dart`

2. **Class Naming**
   - Use PascalCase for class names
   - Widget classes should end with their type (e.g., `UserProfileScreen`, `CustomButtonWidget`)
   - Provider classes should end with `Provider`
   - Service classes should end with `Service`

3. **Code Structure**
   - Maximum file length: 300 lines
   - Break down complex widgets into smaller, reusable components
   - Keep methods focused and single-purpose
   - Use meaningful variable and function names

## State Management
1. **Provider Usage**
   - All state management must use Provider
   - Initialize providers in `main.dart` or a dedicated provider initialization file
   - Keep provider logic separate from UI code
   - Dispose of providers properly to prevent memory leaks

2. **State Organization**
   - Group related state in dedicated provider classes
   - Use ChangeNotifier for state that needs to trigger UI updates
   - Implement proper error handling in providers

## UI Guidelines
1. **Material Design**
   - Follow Material Design guidelines for all UI components
   - Use the provided theme configuration
   - Maintain consistent spacing and typography

2. **Widget Structure**
   - Create reusable widgets for common UI elements
   - Use const constructors where possible
   - Implement proper error boundaries
   - Handle loading and error states consistently

## Firebase Integration
1. **Authentication**
   - Use Firebase Auth for all authentication
   - Implement proper error handling for auth operations
   - Secure sensitive operations with proper authentication checks

2. **Firestore**
   - Structure data models to match Firestore collections
   - Implement proper error handling for database operations
   - Use transactions for critical operations
   - Implement proper security rules

## Security
1. **API Keys and Secrets**
   - Store sensitive data in `.env` file
   - Never commit API keys or secrets to version control
   - Use environment variables for configuration

2. **Data Protection**
   - Implement proper input validation
   - Sanitize user inputs
   - Use secure storage for sensitive data

## Performance
1. **Optimization**
   - Implement proper caching strategies
   - Optimize image loading and caching
   - Use lazy loading where appropriate
   - Implement proper pagination for lists

2. **Memory Management**
   - Dispose of controllers and streams properly
   - Implement proper cleanup in dispose methods
   - Monitor memory usage in development

## Testing
1. **Unit Tests**
   - Write tests for business logic
   - Test provider functionality
   - Test service integrations

2. **Widget Tests**
   - Test UI components
   - Test user interactions
   - Test error states

## Version Control
1. **Git Workflow**
   - Use meaningful commit messages
   - Create feature branches for new development
   - Review code before merging
   - Keep commits focused and atomic

2. **Code Review**
   - Review all code changes
   - Ensure proper error handling
   - Check for security vulnerabilities
   - Verify performance impact

## Documentation
1. **Code Documentation**
   - Document complex logic
   - Add comments for non-obvious code
   - Keep documentation up to date
   - Use proper documentation format

2. **API Documentation**
   - Document all public APIs
   - Include usage examples
   - Document error cases
   - Keep API documentation current

## Dependencies
1. **Package Management**
   - Keep dependencies up to date
   - Review dependency updates for breaking changes
   - Use specific version numbers
   - Document dependency requirements

2. **Custom Dependencies**
   - Create reusable packages for common functionality
   - Document package usage
   - Maintain package versions

## Error Handling
1. **Error Management**
   - Implement proper error boundaries
   - Log errors appropriately
   - Provide user-friendly error messages
   - Handle network errors gracefully

2. **Logging**
   - Use proper logging levels
   - Include relevant context in logs
   - Implement proper error tracking
   - Monitor error rates

## Accessibility
1. **UI Accessibility**
   - Implement proper semantic labels
   - Support screen readers
   - Maintain proper contrast ratios
   - Support dynamic text sizes

2. **Navigation**
   - Implement proper keyboard navigation
   - Support gesture navigation
   - Maintain consistent navigation patterns
   - Provide clear navigation feedback 