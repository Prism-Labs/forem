import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import { SingleCryptoHolding } from './singleCryptoHolding';
import { request } from '@utilities/http';

export class CryptoHoldings extends Component {
  constructor(props) {
    super(props);
    this.state = {
      profileId: props.profileId,
      tokens: props.tokens || [],
      isLoading: !props.tokens
    };

    if (!props.tokens)
      this.loadBalance()
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
        this.setState({ tokens, isLoading: false });
      } else {
        throw new Error(response.statusText);
      }
    } catch (error) {
      this.setState({ isLoading: false, error: true, errorMessage: error.toString() });
    }
  }

  render() {
    return this.state.isLoading ? (<p>Loading... </p>) : (
      <div class="crypto-holding-list">
        {this.state.tokens.map((token, i) => (<SingleCryptoHolding key={i} token={token} />))}
        {!this.state.tokens && (<p>No tokens</p>)}
      </div>
    )
  }
}

CryptoHoldings.displayName = 'Crypto-Holdings';

CryptoHoldings.propTypes = {
  profileId: PropTypes.number.isRequired,
  tokens: PropTypes.array,
};
