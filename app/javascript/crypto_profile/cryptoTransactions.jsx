import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import { SingleCryptoTransaction } from './singleCryptoTransaction';
import { request } from '@utilities/http';

export class CryptoTransactions extends Component {
  constructor(props) {
    super(props);
    this.state = {
      txs: props.txs || [],
      isLoading: !props.txs
    };

    if (!props.txs)
      this.loadTransactions()
  }

  async loadTransactions() {
    try {
      const response = await request(`/api/crypto_profile/${this.props.profileId}/transactions`);
      if (response.ok) {
        const txs = await response.json();
        this.setState({ txs, isLoading: false });
      } else {
        throw new Error(response.statusText);
      }
    } catch (error) {
      this.setState({ isLoading: false, error: true, errorMessage: error.toString() });
    }
  }

  render() {
    return this.state.isLoading ? (<p>Loading...</p>) : (
      <div class="transactions-list px-4 py-3">
        {this.state.txs.map((tx, i) => (<SingleCryptoTransaction key={i} tx={tx} />))}
        {!this.state.txs && (<p>No transactions</p>)}
      </div>
    )
  }
}

CryptoTransactions.displayName = 'Crypto-Transactions';

CryptoTransactions.propTypes = {
  profileId: PropTypes.number.isRequired,
  txs: PropTypes.array,
};
