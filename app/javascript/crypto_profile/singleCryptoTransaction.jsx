import { h, Component } from 'preact';

export class SingleCryptoTransaction extends Component {
  constructor(props) {
    super(props);

    const { tx } = this.props;

    const gasDisplay = Math.round(tx.gas * 100) / 100.0;

    this.state = { 
      timeStampDate: new Date(Number.parseInt(tx.timeStamp) * 1000).toLocaleDateString(),
      timeStampTime: new Date(Number.parseInt(tx.timeStamp) * 1000).toLocaleTimeString(),
      targetAddr: tx.direction == 'outgoing' ? tx.destination : tx.from,
      gasDisplay: gasDisplay < 0.01 ? '< 0.01' : gasDisplay,
      ...tx
    };
  }

  render() {
    return (
      <div className="transaction-container flex flex-row justify-between">
        <div className='flex flex-col align-start justify-center' style={{position: 'relative'}}>
          <span><nobr>{this.state.name}</nobr></span>
          <span>
            <nobr>{this.state.timeStampDate}</nobr><br/>
            <nobr>{this.state.timeStampTime}</nobr>
          </span>
          {/*
          <span className={this.state.txSuccessful ? "transaction-status-label success" : "transaction-status-label failure"}
            title={this.state.txSuccessful ? "Successful transaction":"Failed transaction"} />
          */}
        </div>
        {this.state.direction == 'outgoing' && (
          <div className='flex flex-col align-start justify-center'>
            <span>To</span>
            <span style={{textOverflow:'ellipsis',display:'inline-block',maxWidth:'10em',overflow:'hidden',whiteSpace:'nowrap'}}>
              {this.state.destination}
            </span>
          </div>
        )}
        {this.state.direction == 'incoming' && (
          <div className='flex flex-col align-start justify-center'>
            <span>From</span>
            <span style={{textOverflow:'ellipsis',display:'inline-block',maxWidth:'10em',overflow:'hidden',whiteSpace:'nowrap'}}>
              {this.state.from}
            </span>
          </div>
        )}
        {this.state.direction == 'exchange' && (
          <div className='flex flex-col align-start justify-center'>
            <span>{this.state.subTransactions[0].amount}</span>
            <span>{this.state.subTransactions[0].symbol}</span>
          </div>
        )}
        <div className='flex flex-col align-start justify-center'>&rarr;</div>
        {this.state.direction !== 'exchange' && (
          <div className='flex flex-col align-start justify-center'>
            <span>{this.state.direction=='outgoing' && '-'}{this.state.amount}</span>
            <span>{this.state.symbol}</span>
          </div>
        )}
        {this.state.direction == 'exchange' && (
          <div className='flex flex-col align-start justify-center'>
            <span>{this.state.subTransactions[1].amount}</span>
            <span>{this.state.subTransactions[1].symbol}</span>
          </div>
        )}
        <div className='flex flex-col align-start justify-center'>
          <span className="transaction-amount-label">Gas fee</span>
          <span>{this.state.gasDisplay}ETH</span>
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
