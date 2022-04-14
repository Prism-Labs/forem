import { h, Component } from 'preact';

export class SingleCryptoNft extends Component {
  constructor(props) {
    super(props);
    this.state = { ...this.props.token };
  }

  render() {
    return (
      <div class="token-container">
        <div class="token-img-container">
          <img class="token-img" src={this.state.collectionImg} alt={this.state.collectionName} />
          <div class="token-origin">
            <img class="token-origin-profile" src={this.state.collection.imgProfile} alt="" />
          </div>
          <div class="token-count">
            <span class="line-height _1nv4amt27v">{this.state.balance}</span>
          </div>
        </div>
        <div class="token-detail-container">
          <div class="token-title" style={{width: "calc(100%)"}}>{this.state.collectionName}</div>
          <div class="flex flex-row justify-between">
            <div class="token-value-item">
              <div class="token-value-label">
                <span class="line-height">Floor Price</span>
              </div>
              <div class="token-value-value">{this.state.collection.floorPrice}</div>
            </div>
            <div class="token-value-item">
              <div class="token-value-label"><span class="line-height">Est. Value</span></div>
              <div class="token-value-value">{this.state.balanceUSD}</div>
            </div>
          </div>
        </div>
      </div>
    );
  }
}

SingleCryptoNft.displayName = 'Single NFT';

SingleCryptoNft.propTypes = {
  token: typeof {
    collectionImg: String,
    collectionName: String,
    collection: {
      imgProfile: String,
      floorPrice: String,
    },
    balance: Number,
    balanceUSD: String,
  }
};
