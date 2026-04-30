---
name: "Refactoring"
description: "Best practices and patterns for safe refactoring and technical debt paydown."
user-invocable: false
---

# Refactoring Skill

> Apply this skill during the Edit phase or when technical debt needs to be addressed. Refactoring improves the internal structure of code without changing its external behavior.

---

## Golden Rule of Refactoring

> **Never refactor without tests.** Before changing any code structure, verify that tests exist and pass. After refactoring, verify tests still pass. If tests don't exist, write them first.

---

## When to Refactor

### Always Refactor When:
- A method is too long (>20 lines for complex logic, >50 lines total)
- A class has too many responsibilities (more than one reason to change)
- The same logic appears in 3+ places (Rule of Three)
- The code is hard to understand after reading it twice
- Adding a new feature would require changing many unrelated places
- Tests are hard to write because of coupling or complexity

### Defer Refactoring When:
- The code is about to be deleted or significantly rewritten
- There are no tests (write tests first, then refactor)
- The refactoring would be a massive change with significant regression risk
- The feature is in active development (refactor after the feature is stable)

---

## Common Refactoring Patterns

### Extract Method
**When:** A code block can be named meaningfully and reused, or when a method does multiple things.

**Before:**
```java
public Mono<Order> processOrder(String userId, CartDto cart) {
    // Validate cart
    if (cart.items().isEmpty()) {
        return Mono.error(new InvalidCartException("Cart is empty"));
    }
    if (cart.items().stream().anyMatch(item -> item.quantity() <= 0)) {
        return Mono.error(new InvalidCartException("Invalid item quantity"));
    }
    // Calculate total
    var total = cart.items().stream()
        .mapToDouble(item -> item.price() * item.quantity())
        .sum();
    // Create order
    var order = new Order(userId, cart.items(), total);
    return orderRepository.save(order);
}
```

**After:**
```java
public Mono<Order> processOrder(String userId, CartDto cart) {
    return validateCart(cart)
        .then(Mono.fromCallable(() -> createOrder(userId, cart)))
        .flatMap(orderRepository::save);
}

private Mono<Void> validateCart(CartDto cart) {
    if (cart.items().isEmpty()) return Mono.error(new InvalidCartException("Cart is empty"));
    if (cart.items().stream().anyMatch(item -> item.quantity() <= 0))
        return Mono.error(new InvalidCartException("Invalid item quantity"));
    return Mono.empty();
}

private Order createOrder(String userId, CartDto cart) {
    var total = calculateTotal(cart);
    return new Order(userId, cart.items(), total);
}

private double calculateTotal(CartDto cart) {
    return cart.items().stream().mapToDouble(i -> i.price() * i.quantity()).sum();
}
```

---

### Extract Component (React)
**When:** A JSX block is complex enough to name, or appears in multiple places.

**Before:**
```tsx
function ProductPage({ productId }: { productId: string }) {
  const { data: product } = useProduct(productId);
  return (
    <div>
      <div className="flex items-center gap-2">
        <img src={product?.imageUrl} alt={product?.name} className="h-8 w-8 rounded" />
        <span className="font-semibold">{product?.name}</span>
        {product?.inStock ? (
          <span className="text-green-600 text-sm">In Stock</span>
        ) : (
          <span className="text-red-600 text-sm">Out of Stock</span>
        )}
      </div>
    </div>
  );
}
```

**After:**
```tsx
function ProductAvailabilityBadge({ inStock }: { inStock: boolean }) {
  return inStock
    ? <span className="text-green-600 text-sm">In Stock</span>
    : <span className="text-red-600 text-sm">Out of Stock</span>;
}

function ProductHeader({ product }: { product: Product }) {
  return (
    <div className="flex items-center gap-2">
      <img src={product.imageUrl} alt={product.name} className="h-8 w-8 rounded" />
      <span className="font-semibold">{product.name}</span>
      <ProductAvailabilityBadge inStock={product.inStock} />
    </div>
  );
}
```

---

### Replace Magic Numbers with Constants
```java
// Before
if (failedAttempts > 5) { lockAccount(); }
if (tokenAge > 900) { refreshToken(); }

// After
private static final int MAX_LOGIN_ATTEMPTS = 5;
private static final int ACCESS_TOKEN_EXPIRY_SECONDS = 900;

if (failedAttempts > MAX_LOGIN_ATTEMPTS) { lockAccount(); }
if (tokenAge > ACCESS_TOKEN_EXPIRY_SECONDS) { refreshToken(); }
```

---

### Introduce Parameter Object
**When:** A method takes 4+ parameters that logically belong together.

```java
// Before
public Mono<User> createUser(String email, String password, String firstName, String lastName, String role) { ... }

// After
public record CreateUserCommand(String email, String password, String firstName, String lastName, String role) {}
public Mono<User> createUser(CreateUserCommand command) { ... }
```

---

### Replace Conditional with Polymorphism
**When:** A switch/if-else on a type value drives different behavior.

```java
// Before
double calculateShipping(Order order) {
    return switch (order.type()) {
        case STANDARD -> order.weight() * 0.5;
        case EXPRESS -> order.weight() * 1.5 + 5.0;
        case OVERNIGHT -> order.weight() * 2.0 + 15.0;
    };
}

// After (using strategy pattern)
interface ShippingCalculator {
    double calculate(Order order);
}

record StandardShipping() implements ShippingCalculator {
    public double calculate(Order order) { return order.weight() * 0.5; }
}

// Use via map lookup or factory
```

---

### Decompose Conditional
**When:** Complex boolean conditions obscure intent.

```java
// Before
if (user.subscriptionStatus() == ACTIVE && user.trialDaysRemaining() > 0 
    || user.subscriptionStatus() == PREMIUM && !user.paymentOverdue()) {
    grantAccess();
}

// After
boolean isTrialUser = user.subscriptionStatus() == ACTIVE && user.trialDaysRemaining() > 0;
boolean isPaidUser = user.subscriptionStatus() == PREMIUM && !user.paymentOverdue();
if (isTrialUser || isPaidUser) {
    grantAccess();
}
```

---

### Extract Custom Hook (React)
**When:** A component has complex stateful logic that can be named and potentially reused.

```tsx
// Before (logic mixed into component)
function UserDashboard() {
  const [users, setUsers] = useState<User[]>([]);
  const [search, setSearch] = useState('');
  const [page, setPage] = useState(1);
  const [isLoading, setIsLoading] = useState(false);
  
  useEffect(() => {
    setIsLoading(true);
    fetchUsers({ search, page }).then(setUsers).finally(() => setIsLoading(false));
  }, [search, page]);
  
  // ... render
}

// After (logic in custom hook)
function useUserSearch() {
  const [search, setSearch] = useState('');
  const [page, setPage] = useState(1);
  
  const { data: users, isLoading } = useQuery({
    queryKey: ['users', { search, page }],
    queryFn: () => fetchUsers({ search, page }),
  });
  
  return { users, isLoading, search, setSearch, page, setPage };
}

function UserDashboard() {
  const { users, isLoading, search, setSearch } = useUserSearch();
  // ... clean render
}
```

---

## Refactoring Process

### Step 1: Ensure Tests Exist
```bash
# Check test coverage for the file you're about to refactor
# Java:
./mvnw test -Dtest="[ClassToRefactor]Test" -pl backend

# TypeScript:
npm run test -- --coverage --testPathPattern="[FileToRefactor]"
```
If coverage < 80% or the specific logic isn't tested: **write tests first**.

### Step 2: Make One Change at a Time
Apply one refactoring pattern at a time. Run tests after each change.

```bash
# After each refactoring step:
./mvnw test    # Java
npm run test   # TypeScript
```

Do not combine multiple refactorings in one commit — it makes problems harder to diagnose.

### Step 3: Commit Each Refactoring Separately
```bash
git commit -m "refactor([module]): extract validateCart method from processOrder"
git commit -m "refactor([component]): extract ProductHeader component"
```

### Step 4: Do Not Change Behavior
If you discover a bug while refactoring, do NOT fix it in the same change. Create a separate bug fix commit.

### Step 5: Update Tests if Needed
If the refactoring changes the signature of a method or the structure of a component, update the corresponding tests. The tests should reflect the new structure.

---

## Code Smells to Identify

| Smell | Description | Refactoring Approach |
|-------|------------|---------------------|
| Long Method | Method > 30 lines | Extract Method |
| Large Class | Class with > 500 lines or > 10 public methods | Extract Class |
| Long Parameter List | Method with > 4 parameters | Introduce Parameter Object |
| Duplicate Code | Same logic in 3+ places | Extract Method / Extract Class |
| Dead Code | Unused methods, variables, imports | Delete |
| Magic Numbers | Unexplained numeric/string literals | Extract Constant |
| Shotgun Surgery | Changing one thing requires many unrelated changes | Move Method / Extract Class |
| Feature Envy | Method uses another class's data more than its own | Move Method |
| Data Clumps | Same group of fields appears together in multiple places | Extract Class / Introduce Parameter Object |
| Primitive Obsession | Using primitives where an object would be clearer | Introduce Value Object / Record |
| Switch Statements | Large switch/if-else on type values | Replace with Polymorphism |
| Temporary Field | Field only set in certain code paths | Extract Class |
| Inappropriate Intimacy | Class depends on internals of another class | Move Method / Extract Interface |
