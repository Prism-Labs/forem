import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import { SingleCryptoHolding } from './singleCryptoHolding';
import { request } from '@utilities/http';
import { Spinner } from '@crayons/Spinner/Spinner';
import { BalanceStore } from './balanceStore';

export class CryptoHoldings extends Component {
  constructor(props) {
    super(props);
    this.state = {
      profileId: props.profileId,
      tokens: props.tokens || [],
      nfts: props.nfts || [],
      isLoading: !props.tokens
    };

    if (!props.tokens)
    {
      if (props.balanceStore)
      {
        props.balanceStore.getTokens((tokens, complete) => {
          this.setState({ tokens, isLoading: !complete });
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
      const response = await request(`/api/crypto_profile/${this.props.profileId}/balances`);

      if (response.ok) {
        const tokens = await response.json();
        tokens.sort((a, b) => Number.parseFloat(b.balanceUSD.replace(/[^0-9\.]/g, '')) - Number.parseFloat(a.balanceUSD.replace(/[^0-9\.]/g, '')))
        this.setState({ tokens, isLoading: false });
      } else {
        throw new Error(response.statusText);
      }
    } catch (error) {
      this.setState({ isLoading: false, error: true, errorMessage: error.toString() });
    }
  }

  render() {
    return (
      <div class="crypto-holding-list">
        {this.state.tokens.map((token, i) => (<SingleCryptoHolding key={i} token={token} />))}
        {!this.state.isLoading && !this.state.tokens && (<p>No tokens</p>)}
        {this.state.isLoading && (<p><Spinner /> Loading... </p>)}
      </div>
    )
  }
}

CryptoHoldings.displayName = 'Crypto-Holdings';

CryptoHoldings.propTypes = {
  profileId: PropTypes.number.isRequired,
  tokens: PropTypes.array,
  balanceStore: PropTypes.instanceOf(BalanceStore),
};
