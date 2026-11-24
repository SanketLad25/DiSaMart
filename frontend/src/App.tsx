import { useEffect, useMemo, useState } from 'react'
import { BrowserRouter, Link, Route, Routes, useNavigate, useParams } from 'react-router-dom'
import { Heart, Menu, Search, ShoppingCart, User, Star, Minus, Plus, Trash2, PackageCheck, ChevronRight } from 'lucide-react'
import { categories, products, type Product } from './data'
import { addCartItem, createOrder, type ShippingAddress } from './api'
import './App.css'

type CartItem = Product & { quantity: number }
const formatPrice = (value: number) => new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR', maximumFractionDigits: 0 }).format(value)

function App() {
  const userId = '10000000-0000-0000-0000-000000000001'
  const [cart, setCart] = useState<CartItem[]>(() => {
    const saved = localStorage.getItem('disamart-cart')
    return saved ? JSON.parse(saved) : []
  })
  const [wishlist, setWishlist] = useState<string[]>([])
  const [toast, setToast] = useState('')

  useEffect(() => localStorage.setItem('disamart-cart', JSON.stringify(cart)), [cart])
  useEffect(() => {
    if (!toast) return
    const timer = window.setTimeout(() => setToast(''), 2200)
    return () => window.clearTimeout(timer)
  }, [toast])

  const addToCart = (product: Product) => {
    setCart(items => {
      const existing = items.find(item => item.id === product.id)
      return existing
        ? items.map(item => item.id === product.id ? { ...item, quantity: item.quantity + 1 } : item)
        : [...items, { ...product, quantity: 1 }]
    })
    addCartItem(userId, product)
      .then(() => setToast(`${product.name} added to cart`))
      .catch(error => setToast(error instanceof Error ? error.message : `${product.name} saved locally`))
  }
  const updateQuantity = (id: string, quantity: number) => setCart(items => quantity <= 0 ? items.filter(item => item.id !== id) : items.map(item => item.id === id ? { ...item, quantity } : item))
  const toggleWishlist = (id: string) => setWishlist(items => items.includes(id) ? items.filter(item => item !== id) : [...items, id])
  const cartCount = cart.reduce((sum, item) => sum + item.quantity, 0)

  return (
    <BrowserRouter>
      <div className="app-shell">
        <Header cartCount={cartCount} />
        <Routes>
          <Route path="/" element={<Home wishlist={wishlist} toggleWishlist={toggleWishlist} addToCart={addToCart} />} />
          <Route path="/category/:slug" element={<CategoryPage wishlist={wishlist} toggleWishlist={toggleWishlist} addToCart={addToCart} />} />
          <Route path="/product/:id" element={<ProductDetails wishlist={wishlist} toggleWishlist={toggleWishlist} addToCart={addToCart} />} />
          <Route path="/cart" element={<CartPage cart={cart} updateQuantity={updateQuantity} />} />
          <Route path="/checkout" element={<CheckoutPage cart={cart} clearCart={() => setCart([])} />} />
          <Route path="/order/:id" element={<OrderConfirmation />} />
          <Route path="/wishlist" element={<WishlistPage wishlist={wishlist} toggleWishlist={toggleWishlist} addToCart={addToCart} />} />
          <Route path="/orders" element={<OrdersPage />} />
          <Route path="/profile" element={<ProfilePage />} />
          <Route path="/login" element={<AuthPage />} />
        </Routes>
        {toast && <div className="toast-message">{toast}</div>}
        <Footer />
      </div>
    </BrowserRouter>
  )
}

function Header({ cartCount }: { cartCount: number }) {
  const [search, setSearch] = useState('')
  const navigate = useNavigate()
  const submitSearch = (event: React.FormEvent) => {
    event.preventDefault()
    navigate(`/?search=${encodeURIComponent(search)}`)
  }
  return (
    <>
      <div className="top-strip py-1"><div className="container d-flex justify-content-between"><span>Free delivery on orders above ₹500</span><span>24/7 Customer Support · Easy Returns</span></div></div>
      <header className="navbar-disamart"><div className="container py-2 d-flex align-items-center gap-3">
        <button className="nav-icon-btn d-md-none" aria-label="Menu"><Menu size={22} /></button>
        <Link to="/" className="d-flex align-items-center gap-2 me-md-3"><div className="brand-mark">D</div><div className="brand-name d-none d-sm-block">DiSa<span>Mart</span></div></Link>
        <form className="search-box flex-grow-1" onSubmit={submitSearch}><input value={search} onChange={event => setSearch(event.target.value)} placeholder="Search products, brands and categories" /><button className="search-btn" type="submit" aria-label="Search"><Search size={18} /></button></form>
        <Link to="/profile" className="nav-icon-btn d-none d-sm-grid" title="Profile"><User size={21} /></Link>
        <Link to="/wishlist" className="nav-icon-btn d-none d-sm-grid" title="Wishlist"><Heart size={21} /></Link>
        <Link to="/cart" className="nav-icon-btn" title="Cart"><ShoppingCart size={23} />{cartCount > 0 && <span className="nav-badge">{cartCount}</span>}</Link>
      </div></header>
      <nav className="main-nav d-none d-md-block"><div className="container d-flex">{categories.map(category => <Link key={category.slug} to={`/category/${category.slug}`}>{category.name}</Link>)}<Link to="/orders">My Orders</Link></div></nav>
    </>
  )
}

function ProductCard({ product, wishlist, toggleWishlist, addToCart }: { product: Product; wishlist: string[]; toggleWishlist: (id: string) => void; addToCart: (product: Product) => void }) {
  const discount = Math.round((1 - product.discountPrice / product.originalPrice) * 100)
  return (
    <article className="product-card"><div className="product-image"><span>{product.icon}</span>{discount > 0 && <div className="discount-tag">{discount}% OFF</div>}<button className={`wish-btn ${wishlist.includes(product.id) ? 'active' : ''}`} onClick={() => toggleWishlist(product.id)} aria-label="Wishlist"><Heart size={17} fill={wishlist.includes(product.id) ? 'currentColor' : 'none'} /></button></div>
      <div className="product-body"><Link to={`/product/${product.id}`}><div className="product-category">{product.category}</div><h3 className="product-name">{product.name}</h3></Link><div className="rating mb-2"><Star size={14} fill="currentColor" /> {product.rating.toFixed(1)} <span className="text-muted">· in stock</span></div><div className="d-flex align-items-end gap-2 mb-3"><span className="price-current">{formatPrice(product.discountPrice)}</span><span className="price-original">{formatPrice(product.originalPrice)}</span></div><button className="add-btn" onClick={() => addToCart(product)}>Add to Cart</button></div>
    </article>
  )
}

function Home({ wishlist, toggleWishlist, addToCart }: { wishlist: string[]; toggleWishlist: (id: string) => void; addToCart: (product: Product) => void }) {
  const query = new URLSearchParams(window.location.search).get('search')?.toLowerCase() ?? ''
  const visible = query ? products.filter(product => `${product.name} ${product.category} ${product.description}`.toLowerCase().includes(query)) : products
  const featured = visible.filter(product => product.isFeatured)
  return (
    <main>
      {!query && <div className="container py-4"><section className="hero"><div className="hero-copy"><div className="hero-kicker">FESTIVE MEGA SALE</div><h1>Everything you love,<br />at better prices.</h1><p>Discover fresh deals across groceries, electronics, fashion and home essentials.</p><Link to="/category/electronics-gadgets" className="primary-btn d-inline-block mt-2">Shop the Sale</Link></div><div className="hero-visual"><div className="hero-orb">🛍️</div></div></section></div>}
      <div className="container pb-5">
        {!query && <section className="mb-5"><h2 className="section-title mb-3">Shop by Category</h2><div className="row g-3">{categories.map(category => <div className="col-6 col-md-3" key={category.slug}><Link to={`/category/${category.slug}`}><button className="category-card"><div className="category-icon" style={{ background: category.color }}>{category.icon}</div><strong>{category.name}</strong></button></Link></div>)}</div></section>}
        <section><div className="d-flex justify-content-between align-items-center mb-3"><h2 className="section-title mb-0">{query ? `Results for "${query}"` : 'Featured Products'}</h2><span className="text-muted small">{visible.length} products</span></div>{visible.length === 0 ? <div className="empty-state"><Search size={42} className="text-muted mb-3" /><h4>No products found</h4><p className="text-muted">Try a different search term.</p></div> : <div className="row g-3">{(query ? visible : (featured.length ? featured : visible)).slice(0, 12).map(product => <div className="col-6 col-md-4 col-lg-3" key={product.id}><ProductCard product={product} wishlist={wishlist} toggleWishlist={toggleWishlist} addToCart={addToCart} /></div>)}</div>}</section>
      </div>
    </main>
  )
}

function CategoryPage({ wishlist, toggleWishlist, addToCart }: { wishlist: string[]; toggleWishlist: (id: string) => void; addToCart: (product: Product) => void }) {
  const { slug } = useParams()
  const category = categories.find(item => item.slug === slug)
  const [sort, setSort] = useState('popular')
  const filtered = useMemo(() => {
    const result = products.filter(product => product.category === category?.name)
    if (sort === 'low') return [...result].sort((a, b) => a.discountPrice - b.discountPrice)
    if (sort === 'high') return [...result].sort((a, b) => b.discountPrice - a.discountPrice)
    if (sort === 'rating') return [...result].sort((a, b) => b.rating - a.rating)
    return result
  }, [category, sort])
  return (
    <main className="container py-4"><div className="d-flex justify-content-between align-items-center mb-4"><div><div className="text-muted small">Home <ChevronRight size={12} /> {category?.name}</div><h1 className="section-title fs-2 mt-1">{category?.name}</h1></div><select className="checkout-input" style={{ width: '170px' }} value={sort} onChange={event => setSort(event.target.value)}><option value="popular">Most Popular</option><option value="low">Price: Low to High</option><option value="high">Price: High to Low</option><option value="rating">Top Rated</option></select></div><div className="row g-3">{filtered.map(product => <div className="col-6 col-md-4 col-lg-3" key={product.id}><ProductCard product={product} wishlist={wishlist} toggleWishlist={toggleWishlist} addToCart={addToCart} /></div>)}</div></main>
  )
}

function ProductDetails({ wishlist, toggleWishlist, addToCart }: { wishlist: string[]; toggleWishlist: (id: string) => void; addToCart: (product: Product) => void }) {
  const { id } = useParams()
  const product = products.find(item => item.id === id)
  if (!product) return <main className="container py-5"><div className="empty-state"><h4>Product not found</h4><Link to="/" className="primary-btn d-inline-block mt-3">Continue Shopping</Link></div></main>
  return (
    <main className="container py-5"><div className="row g-5"><div className="col-md-5"><div className="product-image" style={{ height: '430px', borderRadius:'18px' }}><span style={{ fontSize:'150px' }}>{product.icon}</span></div></div><div className="col-md-7"><div className="text-muted">{product.category}</div><h1 className="section-title fs-2 mt-2">{product.name}</h1><div className="rating mb-3"><Star size={16} fill="currentColor" /> {product.rating.toFixed(1)} verified rating</div><div className="d-flex align-items-end gap-3 mb-3"><span className="fs-2 fw-bold">{formatPrice(product.discountPrice)}</span><span className="price-original fs-5">{formatPrice(product.originalPrice)}</span></div><p className="text-muted">{product.description}</p><div className="d-flex gap-3 mt-4"><button className="primary-btn" onClick={() => addToCart(product)}>Add to Cart</button><button className={`wish-btn ${wishlist.includes(product.id) ? 'active' : ''}`} style={{ position:'static', width:'46px', height:'46px' }} onClick={() => toggleWishlist(product.id)}><Heart size={20} fill={wishlist.includes(product.id) ? 'currentColor' : 'none'} /></button></div></div></div></main>
  )
}

function CartPage({ cart, updateQuantity }: { cart: CartItem[]; updateQuantity: (id: string, quantity: number) => void }) {
  const subtotal = cart.reduce((sum, item) => sum + item.discountPrice * item.quantity, 0)
  const shipping = subtotal >= 500 || subtotal === 0 ? 0 : 79
  return (
    <main className="container py-5"><h1 className="section-title fs-2 mb-4">Shopping Cart</h1>{cart.length === 0 ? <div className="empty-state"><ShoppingCart size={48} className="text-muted mb-3" /><h4>Your cart is empty</h4><p className="text-muted">Add something you will love.</p><Link to="/" className="primary-btn d-inline-block mt-2">Continue Shopping</Link></div> : <div className="row g-4"><div className="col-lg-8 d-flex flex-column gap-3">{cart.map(item => <div className="cart-row d-flex align-items-center gap-3" key={item.id}><div style={{ width:'82px', height:'82px', borderRadius:'12px', background:'#edf4f8', display:'grid', placeItems:'center', fontSize:'38px' }}>{item.icon}</div><div className="flex-grow-1"><div className="small text-muted">{item.category}</div><strong>{item.name}</strong><div className="text-primary fw-bold mt-1">{formatPrice(item.discountPrice)}</div></div><div className="quantity-control"><button onClick={() => updateQuantity(item.id, item.quantity - 1)}><Minus size={14} /></button><span>{item.quantity}</span><button onClick={() => updateQuantity(item.id, item.quantity + 1)}><Plus size={14} /></button></div><button className="nav-icon-btn" onClick={() => updateQuantity(item.id, 0)} aria-label="Remove"><Trash2 size={18} /></button></div>)}</div><div className="col-lg-4"><div className="summary-card"><h5 className="fw-bold mb-3">Order Summary</h5><div className="d-flex justify-content-between mb-2"><span>Subtotal</span><strong>{formatPrice(subtotal)}</strong></div><div className="d-flex justify-content-between mb-3"><span>Shipping</span><strong>{shipping === 0 ? 'FREE' : formatPrice(shipping)}</strong></div><hr /><div className="d-flex justify-content-between fs-5 mb-3"><strong>Total</strong><strong>{formatPrice(subtotal + shipping)}</strong></div><Link to="/checkout" className="primary-btn d-block text-center">Proceed to Checkout</Link></div></div></div>}</main>
  )
}

function CheckoutPage({ cart, clearCart }: { cart: CartItem[]; clearCart: () => void }) {
  const navigate = useNavigate()
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const subtotal = cart.reduce((sum, item) => sum + item.discountPrice * item.quantity, 0)
  const shipping = subtotal >= 500 || subtotal === 0 ? 0 : 79
  const submit = (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    setLoading(true)
    setError('')
    const form = new FormData(event.currentTarget)
    const address: ShippingAddress = {
      fullName: String(form.get('fullName') ?? ''),
      phone: String(form.get('phone') ?? ''),
      addressLine1: String(form.get('addressLine1') ?? ''),
      addressLine2: '',
      city: String(form.get('city') ?? ''),
      state: String(form.get('state') ?? ''),
      postalCode: String(form.get('postalCode') ?? ''),
      country: 'India'
    }
    const paymentMethod = form.get('payment') === 'MOCK_CARD' ? 'MOCK_CARD' : 'COD'
    createOrder('20000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', address, paymentMethod)
      .then(result => {
        clearCart()
        navigate(`/order/${result.orderId}`)
      })
      .catch(reason => {
        setError(reason instanceof Error ? reason.message : 'Checkout could not be completed.')
      })
      .finally(() => setLoading(false))
  }
  if (cart.length === 0) return <main className="container py-5"><div className="empty-state"><h4>No items to checkout</h4><Link to="/" className="primary-btn d-inline-block mt-3">Continue Shopping</Link></div></main>
  return (
    <main className="container py-5"><h1 className="section-title fs-2 mb-4">Checkout</h1><form onSubmit={submit} className="row g-4"><div className="col-lg-8"><div className="summary-card"><h5 className="fw-bold mb-3">Delivery Address</h5>{error && <div className="alert alert-danger" role="alert">{error}</div>}<div className="row g-3"><div className="col-md-6"><input className="checkout-input" name="fullName" placeholder="Full name" required /></div><div className="col-md-6"><input className="checkout-input" name="phone" placeholder="Phone number" required /></div><div className="col-12"><input className="checkout-input" name="addressLine1" placeholder="Address line 1" required /></div><div className="col-md-4"><input className="checkout-input" name="city" placeholder="City" required /></div><div className="col-md-4"><input className="checkout-input" name="state" placeholder="State" required /></div><div className="col-md-4"><input className="checkout-input" name="postalCode" placeholder="Postal code" required /></div></div><h5 className="fw-bold mt-4 mb-3">Payment</h5><label className="d-flex align-items-center gap-2 mb-2"><input type="radio" name="payment" value="COD" defaultChecked /> Cash on Delivery</label><label className="d-flex align-items-center gap-2"><input type="radio" name="payment" value="MOCK_CARD" /> Mock Card Payment</label></div></div><div className="col-lg-4"><div className="summary-card"><h5 className="fw-bold mb-3">Payment Summary</h5><div className="d-flex justify-content-between mb-2"><span>Items</span><strong>{cart.length}</strong></div><div className="d-flex justify-content-between mb-2"><span>Subtotal</span><strong>{formatPrice(subtotal)}</strong></div><div className="d-flex justify-content-between mb-3"><span>Shipping</span><strong>{shipping === 0 ? 'FREE' : formatPrice(shipping)}</strong></div><hr /><div className="d-flex justify-content-between fs-5 mb-3"><strong>Total</strong><strong>{formatPrice(subtotal + shipping)}</strong></div><button className="primary-btn w-100" disabled={loading}>{loading ? 'Processing...' : 'Place Order'}</button></div></div></form></main>
  )
}

function OrderConfirmation() {
  const { id } = useParams()
  return <main className="container py-5"><div className="empty-state"><PackageCheck size={64} color="#078c4d" className="mb-3" /><h2 className="section-title">Order confirmed!</h2><p className="text-muted">Your order <strong>{id}</strong> has been placed successfully.</p><Link to="/" className="primary-btn d-inline-block mt-3">Continue Shopping</Link></div></main>
}

function WishlistPage({ wishlist, toggleWishlist, addToCart }: { wishlist: string[]; toggleWishlist: (id: string) => void; addToCart: (product: Product) => void }) {
  const items = products.filter(product => wishlist.includes(product.id))
  return <main className="container py-5"><h1 className="section-title fs-2 mb-4">My Wishlist</h1>{items.length === 0 ? <div className="empty-state"><Heart size={44} className="text-muted mb-3" /><h4>Your wishlist is empty</h4><Link to="/" className="primary-btn d-inline-block mt-3">Explore Products</Link></div> : <div className="row g-3">{items.map(product => <div className="col-6 col-md-4 col-lg-3" key={product.id}><ProductCard product={product} wishlist={wishlist} toggleWishlist={toggleWishlist} addToCart={addToCart} /></div>)}</div>}</main>
}

function OrdersPage() {
  return <main className="container py-5"><h1 className="section-title fs-2 mb-4">My Orders</h1><div className="empty-state"><PackageCheck size={44} className="text-muted mb-3" /><h4>No orders yet</h4><p className="text-muted">Your future orders will appear here.</p><Link to="/" className="primary-btn d-inline-block mt-2">Start Shopping</Link></div></main>
}

function ProfilePage() {
  return <main className="container py-5"><div className="summary-card" style={{ maxWidth:'620px', margin:'0 auto' }}><h1 className="section-title fs-3 mb-3">My Profile</h1><div className="row g-3"><div className="col-md-6"><input className="checkout-input" placeholder="Full name" /></div><div className="col-md-6"><input className="checkout-input" placeholder="Email" /></div><div className="col-12"><input className="checkout-input" placeholder="Phone" /></div></div><button className="primary-btn mt-3">Save Profile</button></div></main>
}

function AuthPage() {
  const [register, setRegister] = useState(false)
  return <main className="container py-5"><div className="summary-card" style={{ maxWidth:'440px', margin:'0 auto' }}><h1 className="section-title fs-3 text-center mb-4">{register ? 'Create Account' : 'Welcome Back'}</h1><div className="d-flex flex-column gap-3">{register && <input className="checkout-input" placeholder="Full name" />}<input className="checkout-input" placeholder="Email address" type="email" /><input className="checkout-input" placeholder="Password" type="password" /><button className="primary-btn">{register ? 'Register' : 'Sign In'}</button></div><button className="nav-icon-btn mx-auto mt-3" onClick={() => setRegister(value => !value)}>{register ? 'Already have an account? Sign in' : 'New here? Create an account'}</button></div></main>
}

function Footer() {
  return <footer className="footer pt-5 pb-4 mt-auto"><div className="container"><div className="row g-4"><div className="col-md-4"><div className="brand-name text-white">DiSa<span>Mart</span></div><p className="mt-2">Modern shopping for everyday life.</p></div><div className="col-md-4"><h6>Shop</h6><div className="d-flex flex-column">{categories.slice(0, 3).map(category => <Link key={category.slug} to={`/category/${category.slug}`}>{category.name}</Link>)}</div></div><div className="col-md-4"><h6>Customer Care</h6><div className="d-flex flex-column"><Link to="/orders">My Orders</Link><Link to="/wishlist">Wishlist</Link><Link to="/profile">My Account</Link></div></div></div><hr /><div className="small">© 2026 DiSaMart. All rights reserved.</div></div></footer>
}

export default App
