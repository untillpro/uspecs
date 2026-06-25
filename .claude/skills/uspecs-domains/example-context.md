# Bounded Context: checkout

## Executive summary

Checkout - turn a shopper's cart into a placed, paid order.

Scope:

- Converts a shopper's cart into a placed, paid order
- Coordinates payment authorization and capture with the external Payment Gateway

Out of scope:

- Cart management (adding/removing items, changing quantities, etc.)

## External actors

Roles:

- 👤 Shopper

Systems:

- ⚙️ Payment Gateway
- ⚙️ Partner Storefront

## Relationships

### Service exposure

```mermaid
graph TD
  checkout(["📦 checkout"])
  cart["📦 cart"]
  auth["📦 auth"]
  notifications["📦 notifications"]
  reviews["📦 reviews"]
  Shopper["👤 Shopper"]
  PartnerStorefront["⚙️ Partner Storefront"]
  PaymentGateway["⚙️ Payment Gateway"]
  cart -..->|"cart contents"| checkout
  auth --->|"shopper identity"| checkout
  PaymentGateway --->|"payment authorization"| checkout
  checkout --->|"order placement UI"| Shopper
  checkout --->|"order placement API"| PartnerStorefront
  checkout --->|"order status UI"| Shopper
  checkout --->|"order status API"| PartnerStorefront
  checkout --->|"order status API"| reviews
  checkout --->|"order events"| notifications
```

Arrows point upstream -> downstream. Edge style encodes the exposure pattern:

- `--->` solid: Open Host Service (ohs) - public, general-purpose contract for many consumers
- `-..->` dotted: Customer-Supplier (c/s) - contract tailored to one or a few known consumers

#### auth -> checkout: shopper identity (ohs + cf)

- Canonical service contract detail: [auth](../auth/context.md)
- `auth` provides `checkout` with a validated shopper identity: stable shopper id, authenticated session, and identity claims needed to place the order
- `checkout` validates shopper identity/token (query)
- Local conformity note: `checkout` adopts `auth`'s stable shopper id and authenticated session as-is; auth publishes no separate formal language for this model-alignment stance

#### cart -> checkout: cart contents (c/s)

- Canonical service contract detail: [cart](../cart/context.md)
- `cart` provides `checkout` with an immutable cart snapshot: cart id, shopper id, product references, quantities, and pricing inputs used to create the order
- `checkout` reads the `cart` snapshot (query)

#### Payment Gateway -> checkout: payment authorization (ohs + acl)

- External provider reference: `Payment Gateway` public payment API documentation
- Contract: gateway public payment API
- `checkout` authorizes/captures payment (command)
- The gateway has no Context spec; `checkout` owns the local ACL translation notes for this relationship
- `PaymentGatewayClient` translates the `Payment Gateway`'s proprietary authorization response into `checkout`'s `PaymentCaptured` event and `Order` status

#### checkout: order events channel (ohs + pl)

- Channel: `checkout.order-events`
- Events: `OrderPlaced`, `PaymentCaptured`
- Language: `OrderEvents.v1`
- Compatibility: backward-compatible additive changes only

Consumers:

- 📦 notifications
  - Consumes order lifecycle events through the broker to send customer-facing messages

#### checkout: order placement API (ohs + pl)

- Contract: `POST /api/checkout/orders`
- Message: place order (command)
- Language: `OrderPlacement.v1`
- Authorization: partner channel scope

Consumers:

- ⚙️ Partner Storefront
  - Place orders through the same public contract

#### checkout: order placement UI (ohs + pl)

- Interface: checkout web UI
- Interaction: place order
- Language: `OrderPlacement.v1`
- Authorization: `Shopper` role

Consumers:

- 👤 Shopper
  - Places an order from their own cart

#### checkout: order status API (ohs + pl)

- Contract: `GET /api/checkout/orders/{order_id}/status`
- Model: `OrderStatus.v1`
- Compatibility: backward-compatible additive changes only
- Authorization: partner channel scope

Consumers:

- ⚙️ Partner Storefront
  - Conform to `OrderStatus.v1` when displaying or synchronizing order state
- 📦 reviews
  - Conforms to `OrderStatus.v1` when checking whether a shopper can review a purchased product

#### checkout: order status UI (ohs + pl)

- Interface: checkout web UI
- Model: `OrderStatus.v1`
- Compatibility: backward-compatible additive changes only
- Authorization: `Shopper` role

Consumers:

- 👤 Shopper
  - Reads order state through the checkout UI

### Model alignment

```mermaid
graph TD
  checkout(["📦 checkout"])
  notifications["📦 notifications"]
  checkout ===>|"message lifecycle terms"| notifications
```

Arrows point upstream -> downstream. Edge style encodes the alignment pattern:

- `===>` thick: Published Language (pl) - the upstream publishes a documented, versioned language/model

#### checkout -> notifications: message lifecycle terms (pl)

- Language: `MessageLifecycleTerms.v1`
- Compatibility: backward-compatible additive changes only
- Separate from `checkout.order-events`; notifications uses this published terminology in message templates and customer-facing copy

Consumers:

- 📦 notifications
  - Uses checkout's message lifecycle terms in customer-facing message templates

---

## Ubiquitous Language

- **Checkout**
  - The process that turns a cart into a placed, paid order

- **Cart snapshot**
  - Immutable copy of the cart's contents taken when checkout begins; the basis for the placed order

## Model specification

### Entities

#### Order

A placed purchase; the Aggregate Root.

Fields:

| Field            | Type      | Description                        |
|------------------|-----------|------------------------------------|
| `order_id`       | `string`  | Stable identifier for the order    |
| `customer_id`    | `string`  | Shopper identity from auth         |
| `status`         | `string`  | Current order lifecycle state      |
| `total_amount`   | `decimal` | Monetary amount of the order total |
| `total_currency` | `string`  | Currency for the order total       |
| `ship_line1`     | `string`  | First line of the shipping address |
| `ship_city`      | `string`  | Shipping city                      |
| `ship_country`   | `string`  | Shipping country                   |

Embeds: `Money` as `total_amount` + `total_currency`; `Address` as `ship_*`.

#### OrderLine

One line item within an Order.

Fields:

| Field         | Type      | Description                          |
|---------------|-----------|--------------------------------------|
| `line_id`     | `string`  | Stable identifier for the order line |
| `product_sku` | `string`  | Product reference from catalog       |
| `quantity`    | `integer` | Ordered quantity                     |
| `unit_amount` | `decimal` | Monetary amount for one unit         |

### Value objects

#### Money

Amount and currency; immutable, value-equal.

Fields:

| Field      | Type      | Description       |
|------------|-----------|-------------------|
| `amount`   | `decimal` | Decimal amount    |
| `currency` | `string`  | ISO currency code |

#### Address

Shipping destination; immutable.

Fields:

| Field     | Type     | Description         |
|-----------|----------|---------------------|
| `line1`   | `string` | First address line  |
| `city`    | `string` | Destination city    |
| `country` | `string` | Destination country |

### Aggregates

#### Order (aggregate)

Root: `Order`.

Encloses its `OrderLines`; external references point only at `Order`, which enforces the invariants that an order has at least one line and that its total equals the sum of its lines.

### ERD

```mermaid
erDiagram
    Order {
        string order_id PK
        string customer_id FK
        string status
    }
    OrderLine {
        string line_id PK
        string product_sku FK
        int quantity
    }
    Order ||--|{ OrderLine : contains
```

## Lifecycle and behavior

### Factories

- `OrderFactory`
  - Builds an Order from a cart snapshot, so the aggregate's invariants hold from creation

### Repositories

- `OrderRepository`
  - Loads and saves Order aggregates by `order_id`

### Services

- `PricingService`
  - Computes the order total, taxes, and discounts; spans `Order`, `OrderLines`, and external tax rules, so it belongs to no single entity

### Events

- `OrderPlaced`
  - Emitted when a shopper confirms an order

- `PaymentCaptured`
  - Emitted when the `⚙️ Payment Gateway` captures payment
