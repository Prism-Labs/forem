import { h, Component } from 'preact';

export class SingleCryptoTransaction extends Component {
  constructor(props) {
    super(props);
    this.state = { ...this.props.tx };
  }

  render() {
    return (
      <div className="transaction-container flex flex-col">
        <div className={this.state.txSuccessful ? "transaction-status-label success" : "transaction-status-label failure"}
            title={this.state.txSuccessful ? "Successful transaction":"Failed transaction"} />
        <div>
          <span className="transaction-amount-label">Hash:</span>
          <code>{this.state.hash}</code>
        </div>
        <div>
          {this.state.direction} {this.state.direction == "outgoing" ? "to" : "from"}
          <code>{this.state.direction == "outgoing" ? this.state.destination : this.state.from}</code>
          at {this.state.timeStamp}
        </div>
        <div className="flex flex-row justify-between">
          <div><span className="transaction-amount-label">Amount: </span><span>{this.state.amount}</span></div>
          <div><span className="transaction-amount-label">Gas: </span><span>{this.state.gas}</span></div>
        </div>
      </div>
    );
  }
}

SingleCryptoTransaction.displayName = 'Single Crypto-Transaction';

SingleCryptoTransaction.propTypes = {
  tx: typeof {
    txSuccessful: Boolean,
    hash: String,
    destination: String,
    from: String,
    direction: String,
    timeStamp: Number,
    amount: Number,
    gas: Number,
  }
};
