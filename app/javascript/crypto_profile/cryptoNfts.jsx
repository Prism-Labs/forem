import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import { SingleCryptoNft } from './singleCryptoNft';
import { request } from '@utilities/http';
import { Spinner } from '@crayons/Spinner/Spinner';
import { BalanceStore } from './balanceStore';

export class CryptoNfts extends Component {
  constructor(props) {
    super(props);
    this.state = {
      profileId: props.profileId,
      nfts: props.nfts || [],
      isLoading: !props.nfts,
    };

    if (!props.nfts)
    {
      if (props.balanceStore )
      {
        props.balanceStore.getNfts((nfts, complete) => {
          this.setState({ nfts, isLoading: !complete });
        });
      }
      else
        this.loadBalance()
    }
  }

  async loadBalance() {
    if (!this.state.profileId) {
      this.setState({ isLoading: false })
      return;
    }
    try {
      const response = await request(`/api/crypto_profile/${this.props.profileId}/nfts`);
      if (response.ok) {
        const nfts = await response.json();
        nfts.sort((a, b) => Number.parseFloat(b.balanceUSD.replace(/[^0-9\.]/g, '')) - Number.parseFloat(a.balanceUSD.replace(/[^0-9\.]/g, '')))
        this.setState({ nfts, isLoading: false });
      } else {
        throw new Error(response.statusText);
      }
    } catch (error) {
      this.setState({ isLoading: false, error: true, errorMessage: error.toString() });
    }
  }

  render() {
    return (
      <div class="nft-grid">
        {this.state.nfts.map((token, i) => (<SingleCryptoNft key={i} token={token} />))}
        {!this.state.isLoading && !this.state.nfts && (<p>No tokens</p>)}
        {this.state.isLoading && (<p><Spinner /> Loading... </p>)}
      </div>
    )
  }
}

CryptoNfts.displayName = 'NFT Holdings';

CryptoNfts.propTypes = {
  profileId: PropTypes.number.isRequired,
  nfts: PropTypes.array,
  balanceStore: PropTypes.instanceOf(BalanceStore),
};
