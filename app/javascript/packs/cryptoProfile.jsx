import { h, render } from 'preact';
import { CryptoHoldings } from '../crypto_profile/cryptoHolidings';
import { CryptoTransactions } from '../crypto_profile/cryptoTransactions';
import { CryptoNfts } from '../crypto_profile/cryptoNfts';
import { BalanceStore } from '../crypto_profile/balanceStore';

function loadElement() {
  const holdingsRoot = document.getElementById('crypto-profile-holdings');
  const transactionsRoot = document.getElementById('crypto-profile-transactions');
  const nftsRoot = document.getElementById('crypto-profile-nfts');

  let cryptoProfileId;

  holdingsRoot && (cryptoProfileId = holdingsRoot.dataset.cryptoProfileId);
  transactionsRoot && (cryptoProfileId = transactionsRoot.dataset.cryptoProfileId);
  nftsRoot && (cryptoProfileId = nftsRoot.dataset.cryptoProfileId);

  const balanceStore = new BalanceStore(cryptoProfileId);

  if (holdingsRoot) {
    render(<CryptoHoldings profileId={Number.parseInt(holdingsRoot.dataset.cryptoProfileId, 10)} balanceStore={balanceStore} />, holdingsRoot);
  }

  if (transactionsRoot) {
    render(<CryptoTransactions profileId={Number.parseInt(transactionsRoot.dataset.cryptoProfileId, 10)} />, transactionsRoot);
  }
  
  if (nftsRoot) {
    render(<CryptoNfts profileId={Number.parseInt(nftsRoot.dataset.cryptoProfileId, 10)} balanceStore={balanceStore} />, nftsRoot);
  }
}

window.InstantClick.on('change', () => {
  loadElement();
});

loadElement();
