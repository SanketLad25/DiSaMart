export type Product = {
  id: string
  name: string
  category: string
  description: string
  originalPrice: number
  discountPrice: number
  stockQuantity: number
  rating: number
  isFeatured: boolean
  icon: string
}

export const categories = [
  { name: 'Grocery', slug: 'grocery', icon: '🛒', color: '#e8f5e9' },
  { name: 'Home Appliances', slug: 'home-appliances', icon: '🏠', color: '#e3f2fd' },
  { name: 'Electronics & Gadgets', slug: 'electronics-gadgets', icon: '📱', color: '#ede7f6' },
  { name: 'Fashion & Clothing', slug: 'fashion-clothing', icon: '👕', color: '#fff3e0' }
]

const seed: Omit<Product, 'icon'>[] = [
  { id:'p01', name:'Premium Basmati Rice', category:'Grocery', description:'Long-grain aromatic rice suitable for everyday cooking.', originalPrice:1499, discountPrice:1299, stockQuantity:120, rating:4.7, isFeatured:true },
  { id:'p02', name:'Whole Wheat Flour', category:'Grocery', description:'Stone-ground whole wheat flour for soft rotis and breads.', originalPrice:349, discountPrice:299, stockQuantity:180, rating:4.6, isFeatured:false },
  { id:'p03', name:'Refined Sugar', category:'Grocery', description:'Clean and finely granulated sugar for cooking and beverages.', originalPrice:220, discountPrice:189, stockQuantity:200, rating:4.4, isFeatured:false },
  { id:'p04', name:'Sunflower Cooking Oil', category:'Grocery', description:'Light cooking oil in a convenient 5 litre container.', originalPrice:899, discountPrice:799, stockQuantity:90, rating:4.5, isFeatured:true },
  { id:'p05', name:'Darjeeling Tea Powder', category:'Grocery', description:'Full-bodied tea powder with a smooth aromatic finish.', originalPrice:399, discountPrice:349, stockQuantity:140, rating:4.8, isFeatured:true },
  { id:'p06', name:'Premium Coffee Powder', category:'Grocery', description:'Dark roasted coffee powder with a rich balanced flavour.', originalPrice:699, discountPrice:599, stockQuantity:100, rating:4.7, isFeatured:false },
  { id:'p07', name:'Fresh Milk', category:'Grocery', description:'Pasteurized full cream milk in a one litre pack.', originalPrice:72, discountPrice:68, stockQuantity:300, rating:4.3, isFeatured:false },
  { id:'p08', name:'Multigrain Biscuits', category:'Grocery', description:'Crispy fibre-rich biscuits with a wholesome taste.', originalPrice:180, discountPrice:149, stockQuantity:160, rating:4.5, isFeatured:false },
  { id:'p09', name:'Mixed Dry Fruits', category:'Grocery', description:'A premium mix of almonds, cashews, raisins, and pistachios.', originalPrice:1199, discountPrice:999, stockQuantity:75, rating:4.8, isFeatured:true },
  { id:'p10', name:'Masala Spice Box', category:'Grocery', description:'Assorted everyday spices for classic Indian cooking.', originalPrice:499, discountPrice:429, stockQuantity:110, rating:4.6, isFeatured:false },
  { id:'p11', name:'Double Door Refrigerator', category:'Home Appliances', description:'Energy-efficient 340 litre refrigerator with frost-free cooling.', originalPrice:38999, discountPrice:34999, stockQuantity:22, rating:4.7, isFeatured:true },
  { id:'p12', name:'Front Load Washing Machine', category:'Home Appliances', description:'8 kg machine with inverter motor and 15 wash programs.', originalPrice:32999, discountPrice:28999, stockQuantity:18, rating:4.6, isFeatured:true },
  { id:'p13', name:'Convection Microwave Oven', category:'Home Appliances', description:'28 litre convection oven for baking and reheating.', originalPrice:14999, discountPrice:12999, stockQuantity:28, rating:4.5, isFeatured:false },
  { id:'p14', name:'Split Air Conditioner', category:'Home Appliances', description:'1.5 ton inverter AC with rapid cooling and saving mode.', originalPrice:46999, discountPrice:39999, stockQuantity:12, rating:4.6, isFeatured:true },
  { id:'p15', name:'Mixer Grinder', category:'Home Appliances', description:'750 watt mixer grinder with three steel jars.', originalPrice:5999, discountPrice:4499, stockQuantity:42, rating:4.4, isFeatured:false },
  { id:'p16', name:'Steel Electric Kettle', category:'Home Appliances', description:'1.8 litre cordless kettle with automatic shutoff.', originalPrice:2499, discountPrice:1999, stockQuantity:65, rating:4.3, isFeatured:false },
  { id:'p17', name:'Bagless Vacuum Cleaner', category:'Home Appliances', description:'Compact cyclonic vacuum cleaner with powerful suction.', originalPrice:7999, discountPrice:6499, stockQuantity:35, rating:4.5, isFeatured:false },
  { id:'p18', name:'RO Water Purifier', category:'Home Appliances', description:'Seven-stage purifier with UV and mineral boost.', originalPrice:17999, discountPrice:14999, stockQuantity:24, rating:4.7, isFeatured:true },
  { id:'p19', name:'BLDC Ceiling Fan', category:'Home Appliances', description:'Silent energy-saving ceiling fan with remote control.', originalPrice:4999, discountPrice:3999, stockQuantity:55, rating:4.6, isFeatured:false },
  { id:'p20', name:'Induction Cooktop', category:'Home Appliances', description:'2000 watt induction cooktop with digital controls.', originalPrice:4999, discountPrice:3999, stockQuantity:48, rating:4.4, isFeatured:false },
  { id:'p21', name:'5G Android Smartphone', category:'Electronics & Gadgets', description:'AMOLED smartphone with 256 GB storage and 50 MP camera.', originalPrice:35999, discountPrice:29999, stockQuantity:32, rating:4.7, isFeatured:true },
  { id:'p22', name:'Business Laptop', category:'Electronics & Gadgets', description:'14 inch laptop with 16 GB RAM and 512 GB SSD.', originalPrice:74999, discountPrice:67999, stockQuantity:16, rating:4.6, isFeatured:true },
  { id:'p23', name:'Smart Watch', category:'Electronics & Gadgets', description:'AMOLED watch with GPS and health tracking.', originalPrice:12999, discountPrice:9999, stockQuantity:52, rating:4.5, isFeatured:true },
  { id:'p24', name:'Wireless Bluetooth Headphones', category:'Electronics & Gadgets', description:'Over-ear headphones with active noise cancellation.', originalPrice:8999, discountPrice:6999, stockQuantity:44, rating:4.6, isFeatured:false },
  { id:'p25', name:'True Wireless Earbuds', category:'Electronics & Gadgets', description:'Low-latency earbuds with a 30-hour battery case.', originalPrice:4999, discountPrice:3499, stockQuantity:80, rating:4.5, isFeatured:true },
  { id:'p26', name:'Portable Bluetooth Speaker', category:'Electronics & Gadgets', description:'Water-resistant speaker with deep bass.', originalPrice:5999, discountPrice:4499, stockQuantity:58, rating:4.4, isFeatured:false },
  { id:'p27', name:'Fast Charging Power Bank', category:'Electronics & Gadgets', description:'20,000 mAh power bank with USB-C charging.', originalPrice:2999, discountPrice:2499, stockQuantity:95, rating:4.5, isFeatured:false },
  { id:'p28', name:'Mechanical Keyboard', category:'Electronics & Gadgets', description:'Tenkeyless mechanical keyboard with hot-swappable switches.', originalPrice:6999, discountPrice:5499, stockQuantity:38, rating:4.7, isFeatured:false },
  { id:'p29', name:'Ergonomic Computer Mouse', category:'Electronics & Gadgets', description:'Wireless ergonomic mouse with silent clicks.', originalPrice:2999, discountPrice:1999, stockQuantity:70, rating:4.4, isFeatured:false },
  { id:'p30', name:'10-inch Android Tablet', category:'Electronics & Gadgets', description:'High-resolution tablet with 8 GB RAM and 128 GB storage.', originalPrice:32999, discountPrice:27999, stockQuantity:26, rating:4.6, isFeatured:true },
  { id:'p31', name:"Men's Cotton T-Shirt", category:'Fashion & Clothing', description:'Regular-fit breathable cotton T-shirt.', originalPrice:999, discountPrice:699, stockQuantity:150, rating:4.4, isFeatured:false },
  { id:'p32', name:"Men's Casual Shirt", category:'Fashion & Clothing', description:'Slim-fit casual shirt in soft easy-care fabric.', originalPrice:1799, discountPrice:1299, stockQuantity:125, rating:4.5, isFeatured:true },
  { id:'p33', name:"Men's Stretch Jeans", category:'Fashion & Clothing', description:'Dark wash stretch jeans with a modern fit.', originalPrice:2999, discountPrice:2299, stockQuantity:88, rating:4.6, isFeatured:false },
  { id:'p34', name:"Women's Printed Dress", category:'Fashion & Clothing', description:'Flowing printed dress with a midi silhouette.', originalPrice:3499, discountPrice:2499, stockQuantity:76, rating:4.7, isFeatured:true },
  { id:'p35', name:"Women's Cotton Kurti", category:'Fashion & Clothing', description:'Soft cotton kurti with subtle embroidery.', originalPrice:1999, discountPrice:1499, stockQuantity:94, rating:4.6, isFeatured:false },
  { id:'p36', name:"Women's Casual Top", category:'Fashion & Clothing', description:'Lightweight casual top with a relaxed fit.', originalPrice:1499, discountPrice:999, stockQuantity:112, rating:4.5, isFeatured:false },
  { id:'p37', name:'All-Season Jacket', category:'Fashion & Clothing', description:'Light insulated jacket with wind-resistant fabric.', originalPrice:4499, discountPrice:3499, stockQuantity:64, rating:4.6, isFeatured:true },
  { id:'p38', name:'Sports Running Shoes', category:'Fashion & Clothing', description:'Cushioned shoes with breathable mesh uppers.', originalPrice:4999, discountPrice:3999, stockQuantity:72, rating:4.7, isFeatured:true },
  { id:'p39', name:'Sports Wear Set', category:'Fashion & Clothing', description:'Moisture-wicking top and shorts set.', originalPrice:2499, discountPrice:1799, stockQuantity:84, rating:4.4, isFeatured:false },
  { id:'p40', name:'Fashion Accessories Set', category:'Fashion & Clothing', description:'Stylish everyday accessories for casual outfits.', originalPrice:1999, discountPrice:1299, stockQuantity:68, rating:4.3, isFeatured:false }
]

const icons: Record<string, string> = {
  Grocery:'🧺', 'Home Appliances':'🏠', 'Electronics & Gadgets':'📱', 'Fashion & Clothing':'👕'
}

export const products: Product[] = seed.map(item => ({ ...item, icon: icons[item.category] }))
