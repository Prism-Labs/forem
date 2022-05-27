export class BalanceStore {
  constructor(profileId) {
    this.isLoading = false;
    this.isLoaded = false;
    this.profileId = profileId;

    this.tokens = [];
    this.nfts = []

    this.tokenListeners = [];
    this.nftListeners = [];
  }

  load() {
    if (this.isLoaded || this.isLoading)
      return false;

    this.isLoading = true;
    const source = new EventSource(`/api/crypto_profile/${this.profileId}/all_balances`);
    source.addEventListener('message', (event) => {});
    source.addEventListener('wallet', (event) => {
      const d = JSON.parse(event.data) || [];
      if (d.length > 0) {
        this.tokens = (this.tokens || []).concat(d)
        this.tokens.sort((a, b) => Number.parseFloat(b.balanceUSD.replace(/[^0-9\.]/g, '')) - Number.parseFloat(a.balanceUSD.replace(/[^0-9\.]/g, '')))
        const tokens = this.tokens.map(t => ({...t}));

        this.tokenListeners.forEach(lf => {
          lf && typeof lf === 'function' && lf(tokens, false)
        })
      }
    });
    source.addEventListener('nft', (event) => {
      const d = JSON.parse(event.data) || [];
      if (d.length > 0) {
        this.nfts = (this.nfts || []).concat(d)
        this.nfts.sort((a, b) => Number.parseFloat(b.balanceUSD.replace(/[^0-9\.]/g, '')) - Number.parseFloat(a.balanceUSD.replace(/[^0-9\.]/g, '')))
        const nfts = this.nfts.map(t => ({...t}));

        this.nftListeners.forEach(lf => {
          lf && typeof lf === 'function' && lf(nfts, false)
        })
      }
    });
    source.onerror = (event) => {
      this.isLoading = false;
      this.isLoaded = true;
      const tokens = this.tokens.map(t => ({...t}));
      const nfts = this.nfts.map(t => ({...t}));

      this.tokenListeners.forEach(lf => {
        lf && typeof lf === 'function' && lf(tokens, true)
      })
      this.nftListeners.forEach(lf => {
        lf && typeof lf === 'function' && lf(nfts, true)
      })

      source.close();
    };
  }

  addTokenListener(callback) {
    this.tokenListeners.push(callback);
  }

  addNftListener(callback) {
    this.nftListeners.push(callback);
  }

  getTokens(listener) {
    if (!this.isLoaded)
    {
      listener && this.addTokenListener(listener);
      this.load()
    }
    else {
      listener && listener(this.tokens, true);
    }
    return this.tokens;
  }

  getNfts(listener) {
    if (!this.isLoaded)
    {
      listener && this.addNftListener(listener);
      this.load()
    }
    else {
      listener && listener(this.nfts, true);
    }
    return this.nfts;
  }

}