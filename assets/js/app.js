import { createApp } from './vendor/vue.esm-browser.prod.js';
import {
  createRouter,
  createWebHashHistory,
  RouterLink,
  RouterView,
} from './vendor/vue-router.esm-browser.prod.js';

const API_BASE = window.__API_BASE__ || `${window.location.origin}/api`;

async function requestJson(path, options = {}) {
  const response = await fetch(`${API_BASE}${path}`, {
    headers: {
      'Content-Type': 'application/json',
      ...(options.headers || {}),
    },
    ...options,
  });

  if (!response.ok) {
    let message = 'Request failed';
    const text = await response.text();
    if (response.status === 405 || response.status === 501) {
      message = 'API endpoint rejected this method. Start the FastAPI backend and use that URL (not a static file server).';
    } else {
      try {
        const payload = JSON.parse(text);
        message = payload.detail || payload.message || message;
      } catch {
        message = text || response.statusText || message;
      }
    }
    throw new Error(message);
  }

  return response.json();
}

function toCurrencyValue(value) {
  if (typeof value === 'number') {
    return `$${value}`;
  }
  return value;
}

const SiteNav = {
  props: {
    actionLabel: {
      type: String,
      default: 'My closet',
    },
    actionTo: {
      type: String,
      default: '/closet',
    },
  },
  components: {
    RouterLink,
  },
  methods: {
    openAuth(mode) {
      window.dispatchEvent(new CustomEvent('open-auth-modal', { detail: { mode } }));
    },
  },
  template: `
    <nav class="nav">
      <router-link to="/" class="logo">VintageLoop</router-link>
      <ul class="nav-links">
        <li><router-link to="/">Listed items</router-link></li>
        <li><router-link to="/women">Women</router-link></li>
        <li><router-link to="/men">Men</router-link></li>
        <li><router-link to="/sell">Sell now</router-link></li>
      </ul>
      <div class="nav-actions">
        <button class="btn btn-ghost" type="button" @click="openAuth('login')">Login</button>
        <button class="btn btn-outline" type="button" @click="openAuth('register')">Create account</button>
        <router-link :to="actionTo" class="btn btn-primary">{{ actionLabel }}</router-link>
      </div>
    </nav>
  `,
};

const PageFooter = {
  props: {
    title: {
      type: String,
      required: true,
    },
    text: {
      type: String,
      required: true,
    },
  },
  template: `
    <footer class="footer">
      <div>
        <h2>{{ title }}</h2>
        <p>{{ text }}</p>
      </div>
    </footer>
  `,
};

const SellButtonBar = {
  components: {
    RouterLink,
  },
  template: `
    <div class="sell-bar">
      <router-link to="/sell" class="btn btn-primary btn-sell">Sell your clothes</router-link>
    </div>
  `,
};

const PageState = {
  props: {
    loading: {
      type: Boolean,
      default: false,
    },
    error: {
      type: String,
      default: '',
    },
  },
  template: `
    <div class="page-state">
      <p v-if="loading">Loading data from the server...</p>
      <p v-else-if="error">{{ error }}</p>
    </div>
  `,
};

const AuthModal = {
  data() {
    return {
      isOpen: false,
      mode: 'login',
      isSubmitting: false,
      message: '',
      error: '',
      countryOptions: [],
      phoneCodeOptions: [],
      registerCountry: '',
      registerPhoneCode: '',
    };
  },
  created() {
    this.modalListener = (event) => {
      this.open(event?.detail?.mode || 'login');
    };
    window.addEventListener('open-auth-modal', this.modalListener);
  },
  unmounted() {
    window.removeEventListener('open-auth-modal', this.modalListener);
  },
  methods: {
    open(mode) {
      this.mode = mode === 'register' ? 'register' : 'login';
      this.isOpen = true;
      this.message = '';
      this.error = '';
      document.body.style.overflow = 'hidden';
      if (this.mode === 'register') {
        this.loadRegisterMeta();
      }
    },
    close() {
      this.isOpen = false;
      this.isSubmitting = false;
      this.error = '';
      document.body.style.overflow = '';
    },
    switchMode(mode) {
      this.mode = mode;
      this.message = '';
      this.error = '';
      if (this.mode === 'register') {
        this.loadRegisterMeta();
      }
    },
    async loadRegisterMeta() {
      if (this.countryOptions.length && this.phoneCodeOptions.length) {
        return;
      }
      try {
        const payload = await requestJson('/public/register-meta');
        this.countryOptions = Array.isArray(payload.countries) ? payload.countries : [];
        this.phoneCodeOptions = Array.isArray(payload.phone_codes) ? payload.phone_codes : [];
      } catch (error) {
        this.error = error.message;
      }
    },
    handleCountryChange() {
      const selected = this.countryOptions.find(
        (entry) => entry.name === this.registerCountry,
      );
      if (selected?.dial_code) {
        this.registerPhoneCode = selected.dial_code;
      }
    },
    async submitLogin() {
      this.isSubmitting = true;
      this.error = '';
      this.message = '';
      try {
        const formData = new FormData(this.$refs.loginForm);
        const payload = {
          email: (formData.get('login-email') || '').toString().trim(),
          password: (formData.get('login-password') || '').toString(),
        };
        const result = await requestJson('/auth/login', {
          method: 'POST',
          body: JSON.stringify(payload),
        });
        this.message = `Welcome back, ${result.user.full_name}.`;
        this.$refs.loginForm.reset();
      } catch (error) {
        this.error = error.message;
      } finally {
        this.isSubmitting = false;
      }
    },
    async submitRegister() {
      this.isSubmitting = true;
      this.error = '';
      this.message = '';
      try {
        const formData = new FormData(this.$refs.registerForm);
        const password = (formData.get('register-password') || '').toString();
        const confirmPassword = (formData.get('register-password-confirm') || '').toString();
        if (password !== confirmPassword) {
          throw new Error('Passwords do not match');
        }
        const payload = {
          full_name: (formData.get('register-name') || '').toString().trim(),
          email: (formData.get('register-email') || '').toString().trim(),
          password,
          country: this.registerCountry.trim(),
          phone_code: this.registerPhoneCode.trim(),
          phone_number: (formData.get('register-phone-number') || '').toString().trim(),
        };
        const result = await requestJson('/auth/register', {
          method: 'POST',
          body: JSON.stringify(payload),
        });
        this.message = `Account created for ${result.full_name}. You can log in now.`;
        this.$refs.registerForm.reset();
        this.registerCountry = '';
        this.registerPhoneCode = '';
      } catch (error) {
        this.error = error.message;
      } finally {
        this.isSubmitting = false;
      }
    },
  },
  template: `
    <div v-if="isOpen" class="auth-modal-backdrop" @click.self="close">
      <section class="auth-modal">
        <div class="auth-modal-header">
          <h2>{{ mode === 'register' ? 'Create account' : 'Login' }}</h2>
          <button class="auth-close" type="button" @click="close">×</button>
        </div>

        <div class="auth-tabs">
          <button type="button" :class="['auth-tab', { active: mode === 'login' }]" @click="switchMode('login')">Login</button>
          <button type="button" :class="['auth-tab', { active: mode === 'register' }]" @click="switchMode('register')">Create account</button>
        </div>

        <form v-if="mode === 'login'" ref="loginForm" class="auth-form" @submit.prevent="submitLogin">
          <label>Email
            <input name="login-email" type="email" required />
          </label>
          <label>Password
            <input name="login-password" type="password" required />
          </label>
          <button class="btn btn-primary" type="submit" :disabled="isSubmitting">
            {{ isSubmitting ? 'Submitting...' : 'Login' }}
          </button>
        </form>

        <form v-else ref="registerForm" class="auth-form" @submit.prevent="submitRegister">
          <label>Full name
            <input name="register-name" type="text" required />
          </label>
          <label>Email
            <input name="register-email" type="email" required />
          </label>
          <label>Password
            <input name="register-password" type="password" minlength="8" required />
          </label>
          <label>Confirm password
            <input name="register-password-confirm" type="password" minlength="8" required />
          </label>
          <label>Country
            <input
              name="register-country"
              type="text"
              list="country-list"
              v-model="registerCountry"
              @change="handleCountryChange"
              @input="handleCountryChange"
              required
            />
          </label>
          <datalist id="country-list">
            <option
              v-for="country in countryOptions"
              :key="country.name"
              :value="country.name"
            ></option>
          </datalist>
          <div class="auth-phone-row">
            <label>Phone code
              <input
                name="register-phone-code"
                type="text"
                list="phone-code-list"
                placeholder="+1"
                v-model="registerPhoneCode"
                required
              />
            </label>
            <label>Phone number
              <input name="register-phone-number" type="tel" required />
            </label>
          </div>
          <datalist id="phone-code-list">
            <option v-for="code in phoneCodeOptions" :key="code" :value="code"></option>
          </datalist>
          <button class="btn btn-primary" type="submit" :disabled="isSubmitting">
            {{ isSubmitting ? 'Submitting...' : 'Create account' }}
          </button>
        </form>

        <p v-if="message" class="form-note">{{ message }}</p>
        <p v-if="error" class="form-error">{{ error }}</p>
      </section>
    </div>
  `,
};

const ItemCard = {
  props: {
    item: {
      type: Object,
      required: true,
    },
  },
  components: {
    RouterLink,
  },
  template: `
    <router-link :to="'/item/' + item.slug" class="item-card-link">
      <article class="item-card collection-card">
        <div :class="['item-photo', item.photoClass]"><span>{{ item.tag }}</span></div>
        <div class="item-details">
          <div class="item-topline">
            <h3>{{ item.title }}</h3>
            <span class="price-tag">{{ item.price }}</span>
          </div>
          <p>{{ item.description }}</p>
          <div class="item-meta">
            <span v-for="metaItem in item.meta" :key="metaItem">{{ metaItem }}</span>
          </div>
        </div>
      </article>
    </router-link>
  `,
};

const ItemGrid = {
  props: {
    items: {
      type: Array,
      required: true,
    },
  },
  components: {
    ItemCard,
  },
  template: `
    <div class="item-grid">
      <item-card
        v-for="item in items"
        :key="item.slug"
        :item="item"
      />
    </div>
  `,
};

const HomePage = {
  components: {
    SiteNav,
    ItemGrid,
    PageFooter,
    SellButtonBar,
    RouterLink,
    PageState,
  },
  data() {
    return {
      loading: true,
      error: '',
      stats: [],
      items: [],
      featuredItem: null,
    };
  },
  async created() {
    try {
      const payload = await requestJson('/home');
      this.stats = payload.stats;
      this.items = payload.items;
      this.featuredItem = payload.featuredItem;
    } catch (error) {
      this.error = error.message;
    } finally {
      this.loading = false;
    }
  },
  template: `
    <div class="page-shell">
      <header class="site-header">
        <site-nav action-label="My closet" action-to="/closet" />
        <section class="hero">
          <div class="hero-text">
            <p class="eyebrow">Pre-loved pieces ready to move</p>
            <h1>Browse all listed items in one place and sell yours next.</h1>
            <p class="subtext">
              Listings now load from the backend so public item information stays outside the browser bundle.
            </p>
            <div class="hero-stats" v-if="!loading && !error">
              <div v-for="stat in stats" :key="stat.label">
                <h3>{{ stat.value }}</h3>
                <p>{{ stat.label }}</p>
              </div>
            </div>
            <page-state v-else :loading="loading" :error="error" />
          </div>

          <router-link
            v-if="featuredItem"
            :to="'/item/' + featuredItem.slug"
            class="hero-card spotlight-card featured-link"
          >
            <div class="card-header">
              <span>Featured listing</span>
              <span class="price-tag">{{ featuredItem.price }}</span>
            </div>
            <div :class="['spotlight-photo', featuredItem.photoClass === 'spotlight-photo' ? '' : featuredItem.photoClass]">
              <span>{{ featuredItem.tag }}</span>
            </div>
            <div class="card-body">
              <h4>{{ featuredItem.title }} · Size {{ featuredItem.size }}</h4>
              <p>{{ featuredItem.condition }} · {{ featuredItem.updatedLabel }}</p>
              <div class="card-progress">
                <span>{{ featuredItem.savedCount }} shoppers saved this item</span>
                <div class="progress-bar">
                  <div class="progress-fill"></div>
                </div>
              </div>
            </div>
          </router-link>
        </section>
      </header>

      <main>
        <section class="section items-section">
          <div class="section-title">
            <p class="eyebrow">Listed items</p>
            <h2>Everything currently for sale.</h2>
            <p class="section-copy">Every card below opens a backend-driven item detail page.</p>
          </div>
          <page-state v-if="loading || error" :loading="loading" :error="error" />
          <item-grid v-else :items="items" />
        </section>
      </main>

      <page-footer
        title="Closet clear-out made simple."
        text="List your next piece and place it directly into the live items feed."
      />
      <sell-button-bar />
    </div>
  `,
};

function createCollectionPage(audience) {
  return {
    components: {
      SiteNav,
      ItemGrid,
      PageFooter,
      PageState,
    },
    data() {
      return {
        loading: true,
        error: '',
        payload: null,
      };
    },
    async created() {
      try {
        this.payload = await requestJson(`/collections/${audience}`);
      } catch (error) {
        this.error = error.message;
      } finally {
        this.loading = false;
      }
    },
    template: `
      <div class="page-shell collection-page">
        <header class="collection-header">
          <site-nav action-label="My closet" action-to="/closet" />
        </header>

        <page-state v-if="loading || error" :loading="loading" :error="error" />

        <template v-else>
          <section class="collection-hero">
            <div class="collection-shell">
              <div class="collection-copy">
                <p class="eyebrow">{{ payload.eyebrow }}</p>
                <h1>{{ payload.title }}</h1>
                <p>{{ payload.description }}</p>
                <div class="pill-row">
                  <span class="pill" v-for="pill in payload.pills" :key="pill">{{ pill }}</span>
                </div>
              </div>
              <aside class="hero-summary">
                <p class="eyebrow">This week</p>
                <h2>{{ payload.summaryTitle }}</h2>
                <div class="summary-grid">
                  <div v-for="item in payload.summary" :key="item.label">
                    <h3>{{ item.value }}</h3>
                    <p>{{ item.label }}</p>
                  </div>
                </div>
              </aside>
            </div>
          </section>

          <main class="page-main">
            <section class="section section-alt">
              <div class="section-title">
                <p class="eyebrow">{{ payload.sectionEyebrow }}</p>
                <h2>{{ payload.sectionTitle }}</h2>
                <p class="section-copy">{{ payload.sectionCopy }}</p>
              </div>
              <item-grid :items="payload.items" />
            </section>
          </main>

          <page-footer :title="payload.footerTitle" :text="payload.footerText" />
        </template>
      </div>
    `,
  };
}

const WomenPage = createCollectionPage('women');
const MenPage = createCollectionPage('men');

const ItemDetailPage = {
  components: {
    SiteNav,
    PageFooter,
    RouterLink,
    PageState,
  },
  data() {
    return {
      loading: true,
      error: '',
      item: null,
    };
  },
  watch: {
    '$route.params.slug': {
      immediate: true,
      handler() {
        this.loadItem();
      },
    },
  },
  methods: {
    async loadItem() {
      this.loading = true;
      this.error = '';
      try {
        this.item = await requestJson(`/items/${this.$route.params.slug}`);
      } catch (error) {
        this.error = error.message;
      } finally {
        this.loading = false;
      }
    },
  },
  template: `
    <div class="page-shell detail-page">
      <header class="collection-header">
        <site-nav action-label="My closet" action-to="/closet" />
      </header>

      <page-state v-if="loading || error" :loading="loading" :error="error" />

      <template v-else-if="item">
        <main class="detail-main">
          <section class="detail-hero">
            <div :class="['detail-photo', item.photoClass]">
              <span>{{ item.tag }}</span>
            </div>
            <div class="detail-copy">
              <p class="eyebrow">{{ item.category }} · {{ item.audience }}</p>
              <h1>{{ item.title }}</h1>
              <p class="detail-price-row">
                <span class="detail-price">{{ item.price }}</span>
                <span v-if="item.originalPrice" class="detail-original">{{ item.originalPrice }}</span>
              </p>
              <p class="detail-text">{{ item.longDescription }}</p>

              <div class="detail-highlights">
                <span class="pill" v-for="highlight in item.highlights" :key="highlight">{{ highlight }}</span>
              </div>

              <div class="detail-actions">
                <router-link :to="item.backRoute" class="btn btn-outline">Back to collection</router-link>
                <router-link to="/sell" class="btn btn-primary">Sell something similar</router-link>
              </div>
            </div>
          </section>

          <section class="detail-grid">
            <article class="detail-panel">
              <h2>Item information</h2>
              <div class="detail-specs">
                <div><span>Brand</span><strong>{{ item.brand }}</strong></div>
                <div><span>Color</span><strong>{{ item.color }}</strong></div>
                <div><span>Material</span><strong>{{ item.material }}</strong></div>
                <div><span>Size</span><strong>{{ item.size }}</strong></div>
                <div><span>Condition</span><strong>{{ item.condition }}</strong></div>
                <div><span>Location</span><strong>{{ item.location }}</strong></div>
              </div>
            </article>

            <article class="detail-panel">
              <h2>Shipping and fit</h2>
              <div class="detail-list">
                <div><span>Measurements</span><strong>{{ item.measurements }}</strong></div>
                <div><span>Visible flaws</span><strong>{{ item.flaws }}</strong></div>
                <div><span>Ships within</span><strong>{{ item.shippingTime }}</strong></div>
                <div><span>Shipping cost</span><strong>{{ item.shippingCost }}</strong></div>
                <div><span>Returns</span><strong>{{ item.returnsPolicy }}</strong></div>
                <div><span>Saved by</span><strong>{{ item.savedCount }} shoppers</strong></div>
              </div>
            </article>
          </section>
        </main>

        <page-footer
          title="Item details are now server-backed."
          text="The browser only receives public listing information from the API when you open a product."
        />
      </template>
    </div>
  `,
};

const SellPage = {
  components: {
    SiteNav,
    PageFooter,
  },
  data() {
    return {
      submitMessage: '',
      submitError: '',
      isSubmitting: false,
    };
  },
  methods: {
    async submitForm() {
      this.submitMessage = '';
      this.submitError = '';
      this.isSubmitting = true;

      try {
        const formData = new FormData(this.$refs.sellForm);
        const payload = {
          title: formData.get('item-name')?.trim() || '',
          category: formData.get('category') || '',
          brand: formData.get('brand')?.trim() || '',
          size: formData.get('size') || '',
          audience: (formData.get('gender') || 'women').toLowerCase(),
          color: formData.get('color')?.trim() || '',
          material: formData.get('material')?.trim() || '',
          price: Number(formData.get('price') || 0),
          original_price: formData.get('original-price') ? Number(formData.get('original-price')) : null,
          condition: formData.get('condition') || '',
          wear: formData.get('wear')?.trim() || null,
          measurements: formData.get('measurements')?.trim() || null,
          flaws: formData.get('flaws')?.trim() || null,
          description: formData.get('description')?.trim() || '',
          location: formData.get('location')?.trim() || '',
          shipping_time: formData.get('shipping-time') || '',
          shipping_cost: formData.get('shipping-cost') || '',
          returns_policy: formData.get('returns') || '',
          seller_name: formData.get('seller-name')?.trim() || '',
          seller_email: formData.get('seller-email')?.trim() || '',
          seller_phone: formData.get('seller-phone')?.trim() || null,
          payment: formData.get('payment') || '',
          accept_offers: formData.get('offers') === 'on',
          allow_bundle_discounts: formData.get('bundle') === 'on',
          boost_listing: formData.get('featured') === 'on',
          share_to_homepage: formData.get('share') === 'on',
        };

        const created = await requestJson('/items', {
          method: 'POST',
          body: JSON.stringify(payload),
        });

        this.submitMessage = `Listing "${created.title}" saved to the backend. Photo storage can be connected next.`;
        this.$refs.sellForm.reset();
      } catch (error) {
        this.submitError = error.message;
      } finally {
        this.isSubmitting = false;
      }
    },
    clearForm() {
      this.submitMessage = '';
      this.submitError = '';
      this.$refs.sellForm.reset();
    },
  },
  template: `
    <div class="page-shell sell-page">
      <header class="sell-header">
        <site-nav action-label="Back to shop" action-to="/" />
      </header>

      <main class="sell-hero">
        <section class="sell-intro">
          <p class="eyebrow">Create a listing</p>
          <h1>Tell buyers everything about your old cloth.</h1>
          <p>
            The form now posts item data to the backend instead of keeping listing records in frontend code.
          </p>

          <div class="seller-notes">
            <article class="note-card">
              <h3>Server-side storage</h3>
              <p>Listing details are saved by the API, so item records no longer live in the browser bundle.</p>
            </article>
            <article class="note-card">
              <h3>Validation happens on submit</h3>
              <p>The backend now validates core fields before a listing is accepted into the catalog.</p>
            </article>
            <article class="note-card">
              <h3>Uploads can come next</h3>
              <p>This version secures listing fields first. File storage can be added once you choose where images live.</p>
            </article>
          </div>
        </section>

        <section class="sell-panel">
          <div class="panel-header">
            <h2>Clothing information</h2>
            <p>Complete the form below to prepare your resale listing.</p>
          </div>

          <form ref="sellForm" class="sell-form" @submit.prevent="submitForm" @reset.prevent="clearForm">
            <div class="form-section">
              <h3>Basic details</h3>
              <div class="form-grid">
                <div class="field field-full">
                  <label for="item-name">Listing title</label>
                  <input id="item-name" name="item-name" type="text" placeholder="Example: Vintage Levi's denim jacket" />
                </div>
                <div class="field">
                  <label for="category">Category</label>
                  <select id="category" name="category">
                    <option value="">Select category</option>
                    <option>Jacket</option>
                    <option>Dress</option>
                    <option>Shirt</option>
                    <option>Pants</option>
                    <option>Sweater</option>
                    <option>Bag</option>
                    <option>Blazer</option>
                    <option>Coat</option>
                    <option>Shoes</option>
                  </select>
                </div>
                <div class="field">
                  <label for="brand">Brand</label>
                  <input id="brand" name="brand" type="text" placeholder="Brand name" />
                </div>
                <div class="field">
                  <label for="size">Size</label>
                  <select id="size" name="size">
                    <option value="">Select size</option>
                    <option>XS</option>
                    <option>S</option>
                    <option>M</option>
                    <option>L</option>
                    <option>XL</option>
                    <option>One size</option>
                    <option>30</option>
                  </select>
                </div>
                <div class="field">
                  <label for="gender">Best fit for</label>
                  <select id="gender" name="gender">
                    <option value="">Select option</option>
                    <option>Women</option>
                    <option>Men</option>
                    <option>Unisex</option>
                    <option>Kids</option>
                  </select>
                </div>
                <div class="field">
                  <label for="color">Color</label>
                  <input id="color" name="color" type="text" placeholder="Example: Faded blue" />
                </div>
                <div class="field">
                  <label for="material">Material</label>
                  <input id="material" name="material" type="text" placeholder="Example: 100% cotton" />
                </div>
                <div class="field">
                  <label for="price">Price</label>
                  <input id="price" name="price" type="number" placeholder="28" min="1" />
                </div>
                <div class="field">
                  <label for="original-price">Original retail price</label>
                  <input id="original-price" name="original-price" type="number" placeholder="95" min="1" />
                </div>
              </div>
            </div>

            <div class="form-section">
              <h3>Condition and fit</h3>
              <div class="form-grid">
                <div class="field">
                  <label for="condition">Condition</label>
                  <select id="condition" name="condition">
                    <option value="">Select condition</option>
                    <option>Like new</option>
                    <option>Excellent condition</option>
                    <option>Very good condition</option>
                    <option>Great condition</option>
                    <option>Good condition</option>
                    <option>Fair condition</option>
                    <option>Worn once</option>
                    <option>Tailored fit</option>
                    <option>Gently used</option>
                    <option>Clean interior</option>
                  </select>
                </div>
                <div class="field">
                  <label for="wear">Times worn</label>
                  <input id="wear" name="wear" type="text" placeholder="Example: 4-5 times" />
                </div>
                <div class="field">
                  <label for="measurements">Measurements</label>
                  <input id="measurements" name="measurements" type="text" placeholder="Chest 40in, Length 24in" />
                </div>
                <div class="field">
                  <label for="flaws">Visible flaws</label>
                  <input id="flaws" name="flaws" type="text" placeholder="Example: Small fade on cuff" />
                </div>
                <div class="field field-full">
                  <label for="description">Description</label>
                  <textarea id="description" name="description" placeholder="Describe the style, fit, condition, and anything a buyer should know."></textarea>
                </div>
              </div>
            </div>

            <div class="form-section">
              <h3>Photos and shipping</h3>
              <div class="form-grid">
                <div class="field field-full upload-box">
                  <label for="photos">Upload item photos</label>
                  <input id="photos" name="photos" type="file" multiple />
                  <p>Image file storage is not wired yet. The backend currently stores the text listing data only.</p>
                </div>
                <div class="field">
                  <label for="location">Item location</label>
                  <input id="location" name="location" type="text" placeholder="City, State" />
                </div>
                <div class="field">
                  <label for="shipping-time">Ships within</label>
                  <select id="shipping-time" name="shipping-time">
                    <option value="">Select shipping time</option>
                    <option>24 hrs</option>
                    <option>2 days</option>
                    <option>3 days</option>
                    <option>1 week</option>
                  </select>
                </div>
                <div class="field">
                  <label for="shipping-cost">Shipping cost</label>
                  <select id="shipping-cost" name="shipping-cost">
                    <option value="">Select option</option>
                    <option>Free shipping</option>
                    <option>Buyer pays</option>
                    <option>Included in price</option>
                  </select>
                </div>
                <div class="field">
                  <label for="returns">Returns</label>
                  <select id="returns" name="returns">
                    <option value="">Select option</option>
                    <option>No returns</option>
                    <option>Returns within 3 days</option>
                    <option>Returns within 7 days</option>
                  </select>
                </div>
              </div>
            </div>

            <div class="form-section">
              <h3>Seller preferences</h3>
              <div class="checkbox-grid">
                <label class="checkbox-item"><input type="checkbox" name="offers" /> Accept offers</label>
                <label class="checkbox-item"><input type="checkbox" name="bundle" /> Allow bundle discounts</label>
                <label class="checkbox-item"><input type="checkbox" name="featured" /> Boost listing for faster sale</label>
                <label class="checkbox-item"><input type="checkbox" name="share" /> Share to homepage once approved</label>
              </div>
            </div>

            <div class="form-section">
              <h3>Contact details</h3>
              <div class="form-grid">
                <div class="field">
                  <label for="seller-name">Seller name</label>
                  <input id="seller-name" name="seller-name" type="text" placeholder="Your full name" />
                </div>
                <div class="field">
                  <label for="seller-email">Email</label>
                  <input id="seller-email" name="seller-email" type="email" placeholder="you@example.com" />
                </div>
                <div class="field">
                  <label for="seller-phone">Phone number</label>
                  <input id="seller-phone" name="seller-phone" type="tel" placeholder="+1 555 123 4567" />
                </div>
                <div class="field">
                  <label for="payment">Preferred payout</label>
                  <select id="payment" name="payment">
                    <option value="">Select payout method</option>
                    <option>Bank transfer</option>
                    <option>PayPal</option>
                    <option>Store credit</option>
                  </select>
                </div>
              </div>
            </div>

            <div class="form-actions">
              <button type="submit" class="btn btn-primary" :disabled="isSubmitting">
                {{ isSubmitting ? 'Saving...' : 'Publish listing' }}
              </button>
              <button type="reset" class="btn btn-light">Clear form</button>
            </div>
            <p v-if="submitMessage" class="form-note">{{ submitMessage }}</p>
            <p v-if="submitError" class="form-error">{{ submitError }}</p>
          </form>
        </section>
      </main>

      <page-footer
        title="Ready to list the next piece?"
        text="Complete the form, publish the listing, and send buyers straight to your closet."
      />
    </div>
  `,
};

const ClosetPage = {
  components: {
    SiteNav,
    PageFooter,
    RouterLink,
    PageState,
  },
  data() {
    return {
      loading: true,
      error: '',
      items: [],
      tasks: [],
    };
  },
  computed: {
    activeCount() {
      return this.items.filter((item) => item.status === 'live').length;
    },
    draftCount() {
      return this.items.filter((item) => item.status === 'draft').length;
    },
    soldCount() {
      return this.items.filter((item) => item.status === 'sold').length;
    },
    earnings() {
      return this.items
        .filter((item) => item.status === 'sold')
        .reduce((total, item) => total + item.earning, 0);
    },
  },
  async created() {
    try {
      const payload = await requestJson('/closet');
      this.items = payload.items;
      this.tasks = payload.tasks;
    } catch (error) {
      this.error = error.message;
    } finally {
      this.loading = false;
    }
  },
  template: `
    <div class="page-shell closet-page">
      <header class="closet-header">
        <site-nav action-label="Add listing" action-to="/sell" />
      </header>

      <page-state v-if="loading || error" :loading="loading" :error="error" />

      <template v-else>
        <main class="closet-main">
          <section class="closet-hero">
            <div class="closet-copy">
              <p class="eyebrow">Seller dashboard</p>
              <h1>Manage everything in My closet.</h1>
              <p>
                Closet information now loads from the backend instead of being bundled into the frontend.
              </p>
              <div class="closet-actions">
                <router-link to="/sell" class="btn btn-primary">Create new listing</router-link>
                <router-link to="/" class="btn btn-light">View marketplace</router-link>
              </div>
            </div>

            <aside class="stats-panel">
              <h2>Closet snapshot</h2>
              <div class="stats-list">
                <div><span>Active listings</span><strong>{{ activeCount }}</strong></div>
                <div><span>Drafts waiting</span><strong>{{ draftCount }}</strong></div>
                <div><span>Sold this month</span><strong>{{ soldCount }}</strong></div>
                <div><span>Earnings this month</span><strong>{{ toCurrencyValue(earnings) }}</strong></div>
              </div>
            </aside>
          </section>

          <section class="dashboard-grid">
            <div class="dashboard-panel">
              <div class="panel-row">
                <div>
                  <h2>Your items</h2>
                  <p>Current listings and their latest status.</p>
                </div>
                <router-link to="/sell" class="btn btn-outline">Add another</router-link>
              </div>

              <div class="closet-list">
                <article class="closet-item" v-for="item in items" :key="item.slug">
                  <div :class="['closet-thumb', item.photoClass]">{{ item.tag }}</div>
                  <div class="closet-details">
                    <div class="panel-row">
                      <h3>{{ item.title }}</h3>
                      <span :class="['status-pill', statusClass(item.status)]">{{ item.statusLabel }}</span>
                    </div>
                    <p>{{ item.details }}</p>
                    <div class="closet-meta">
                      <span v-for="metaItem in item.meta" :key="metaItem">{{ metaItem }}</span>
                    </div>
                  </div>
                </article>
              </div>
            </div>

            <aside class="dashboard-panel">
              <div class="panel-row">
                <div>
                  <h2>Next actions</h2>
                  <p>Tasks that help this closet sell faster.</p>
                </div>
              </div>
              <div class="task-list">
                <article class="task" v-for="task in tasks" :key="task.title">
                  <h3>{{ task.title }}</h3>
                  <p>{{ task.description }}</p>
                </article>
              </div>
            </aside>
          </section>
        </main>

        <page-footer
          title="Keep your closet active."
          text="Add new items regularly and refresh older listings to stay visible to buyers."
        />
      </template>
    </div>
  `,
  methods: {
    statusClass(status) {
      return {
        live: 'status-live',
        draft: 'status-draft',
        sold: 'status-sold',
      }[status];
    },
    toCurrencyValue,
  },
};

const routes = [
  {
    path: '/',
    component: HomePage,
    meta: { title: 'VintageLoop - Home' },
  },
  {
    path: '/women',
    component: WomenPage,
    meta: { title: "VintageLoop - Women's Listings" },
  },
  {
    path: '/men',
    component: MenPage,
    meta: { title: "VintageLoop - Men's Listings" },
  },
  {
    path: '/item/:slug',
    component: ItemDetailPage,
    meta: { title: 'VintageLoop - Item Details' },
  },
  {
    path: '/sell',
    component: SellPage,
    meta: { title: 'VintageLoop - Sell Your Clothes' },
  },
  {
    path: '/closet',
    component: ClosetPage,
    meta: { title: 'VintageLoop - My Closet' },
  },
];

const router = createRouter({
  history: createWebHashHistory(),
  routes,
});

router.afterEach((to) => {
  document.title = to.meta.title || 'VintageLoop';
});

createApp({
  components: {
    RouterView,
    AuthModal,
  },
  template: `
    <div class="app-root">
      <router-view />
      <auth-modal />
    </div>
  `,
})
  .use(router)
  .mount('#app');
