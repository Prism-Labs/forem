import { h, Component } from 'preact';
import PropTypes from 'prop-types';

export class SingleCryptoHolding extends Component {
  constructor(props) {
    super(props);
    this.state = { ...this.props.token };
  }

  render() {
    return (
      <div className="profile-wallet-token flex justify-between items-center" role="button">
        <div className="flex items-center">
          <div className="_1nv4amt19" style="min-width: 48px; max-width: 48px;">
            <div style="transition: all 0.2s ease-in-out 0s;">
              <div className="_1nv4amtfk _1nv4amt1sq">
                <div className="_1nv4amt2ke _1nv4amt2gn">
                  <img src={this.state.tokenImageUrl} style={{width: "32px", height: "32px", borderRadius: "100%"}} alt="" />
                </div>
              </div>
            </div>
          </div>
          <div className="_1nv4amt2a0 _1nv4amt27v">{this.state.symbol}
            <div className="_1nv4amt2f8 _1nv4amt2a4 _1nv4amt280">{this.state.price}</div>
          </div>
        </div>
        <div className="flex flex-col items-end justify-center">
          <div className="_1nv4amt2b8 _1nv4amt2a0 _1nv4amt27v">{this.state.balanceUSD}</div>
          <div className="_1nv4amt2f8 _1nv4amt2a4 _1nv4amt280">{this.state.balance}</div>
        </div>
      </div>
    );
  }
}

SingleCryptoHolding.displayName = 'Single Holding Item';

SingleCryptoHolding.propTypes = {
  token: PropTypes.shape({
    tokenImageUrl: PropTypes.string,
    symbol: PropTypes.string,
    balance: PropTypes.number,
    price: PropTypes.number,
    balanceUSD: PropTypes.string,
  })
};
