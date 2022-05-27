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
      const ex = this.tokens || [];
      const d = JSON.parse(event.data) || [];
      if (d.length > 0) {
        const tokens = ex.concat(d)
        tokens.sort((a, b) => Number.parseFloat(b.balanceUSD.replace(/[^0-9\.]/g, '')) - Number.parseFloat(a.balanceUSD.replace(/[^0-9\.]/g, '')))
        this.tokens = tokens;

        this.tokenListeners.forEach(lf => {
          lf && typeof lf === 'function' && lf(tokens, false)
        })
      }
    });
    source.addEventListener('nft', (event) => {
      const ex = this.nfts || [];
      const d = JSON.parse(event.data) || [];
      if (d.length > 0) {
        const nfts = ex.concat(d)
        nfts.sort((a, b) => Number.parseFloat(b.balanceUSD.replace(/[^0-9\.]/g, '')) - Number.parseFloat(a.balanceUSD.replace(/[^0-9\.]/g, '')))
        this.nfts = nfts;

        this.nftListeners.forEach(lf => {
          lf && typeof lf === 'function' && lf(nfts, false)
        })
      }
    });
    source.onerror = (event) => {
      this.isLoading = false;
      this.isLoaded = true;

      this.tokenListeners.forEach(lf => {
        lf && typeof lf === 'function' && lf(this.tokens, true)
      })
      this.nftListeners.forEach(lf => {
        lf && typeof lf === 'function' && lf(this.nfts, true)
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