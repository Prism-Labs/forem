import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import { SingleCryptoNft } from './singleCryptoNft';
import { request } from '@utilities/http';

export class CryptoNfts extends Component {
  constructor(props) {
    super(props);
    this.state = {
      nfts: props.nfts || [],
      isLoading: !props.nfts,
    };

    if (!props.nfts)
      this.loadBalance()
  }

  async loadBalance() {
    try {
      const response = await request(`/api/crypto_profile/${this.props.profileId}/nfts`);
      if (response.ok) {
        const nfts = await response.json();
        this.setState({ nfts, isLoading: false });
      } else {
        throw new Error(response.statusText);
      }
    } catch (error) {
      this.setState({ error: true, errorMessage: error.toString() });
    }
  }

  render() {
    return this.state.isLoading ? (<p>Loading... </p>) : (
      <div class="px-4 py-3 nft-grid">
        {this.state.nfts.map((token, i) => (<SingleCryptoNft key={i} token={token} />))}
        {!this.state.nfts && (<p>No tokens</p>)}
      </div>
    )
  }
}

CryptoNfts.displayName = 'NFT Holdings';

CryptoNfts.propTypes = {
  profileId: PropTypes.number.isRequired,
  nfts: PropTypes.array,
};
