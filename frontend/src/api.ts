import axios from 'axios'
import type { Product } from './data'

export const api = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL ?? '/api',
  timeout: 8000,
  headers: { 'Content-Type': 'application/json' }
})

api.interceptors.response.use(
  response => response,
  error => {
    if (error.code === 'ECONNABORTED') {
      throw new Error('The request timed out. Please try again.')
    }
    if (!error.response) {
      throw new Error('DiSaMart services are currently unavailable.')
    }
    throw error
  }
)

export type CartApiItem = {
  id: string
  productId: string
  productName: string
  unitPrice: number
  quantity: number
  lineTotal: number
}

export type CartApiResponse = {
  id: string
  userId: string
  currencyCode: string
  items: CartApiItem[]
  subtotal: number
}

export async function getCart(userId: string): Promise<CartApiResponse> {
  const response = await api.get<CartApiResponse>(`/cart/carts/${userId}`)
  return response.data
}

export async function addCartItem(userId: string, product: Product, quantity = 1): Promise<{ itemId: string }> {
  const mappedProductId = /^[0-9a-f-]{36}$/i.test(product.id)
    ? product.id
    : `B0000000-0000-4000-8000-${product.id.replace(/[^a-z0-9]/gi, '').padEnd(12, '0').slice(-12).padStart(12, '0')}`
  const response = await api.post(`/cart/carts/${userId}/items`, {
    productId: mappedProductId,
    productName: product.name,
    unitPrice: product.discountPrice,
    quantity
  })
  return response.data
}

export async function updateCartItem(userId: string, itemId: string, quantity: number): Promise<void> {
  await api.put(`/cart/carts/${userId}/items/${itemId}`, { quantity })
}

export async function removeCartItem(userId: string, itemId: string): Promise<void> {
  await api.delete(`/cart/carts/${userId}/items/${itemId}`)
}

export async function clearCart(userId: string): Promise<void> {
  await api.delete(`/cart/carts/${userId}`)
}

export type ShippingAddress = {
  fullName: string
  phone: string
  addressLine1: string
  addressLine2?: string
  city: string
  state: string
  postalCode: string
  country: string
}

export type CreateOrderRequest = {
  userId: string
  cartId: string
  currencyCode: string
  paymentMethod: 'COD' | 'MOCK_CARD'
  shippingAddress: ShippingAddress
}

export type OrderConfirmation = {
  orderId: string
  status: string
  grandTotal: number
  paymentId: string
  shipmentId: string
  trackingNumber: string
}

export async function createOrder(cartId: string, userId: string, address: ShippingAddress, paymentMethod: 'COD' | 'MOCK_CARD'): Promise<OrderConfirmation> {
  const response = await api.post<OrderConfirmation>('/checkout/checkout/orders', {
    userId,
    cartId,
    currencyCode: 'INR',
    paymentMethod,
    shippingAddress: address
  })
  return response.data
}

export async function getFeaturedProducts(): Promise<Product[]> {
  const response = await api.get<Product[]>('/catalog/products/featured')
  return response.data
}

