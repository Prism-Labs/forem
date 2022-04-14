import { h, render } from 'preact';
import { CryptoHoldings } from '../crypto_profile/cryptoHolidings';
import { CryptoTransactions } from '../crypto_profile/cryptoTransactions';
import { CryptoNfts } from '../crypto_profile/cryptoNfts';

function loadElement() {
  const holdingsRoot = document.getElementById('crypto-profile-holdings');
  if (holdingsRoot) {
    render(<CryptoHoldings profileId={Number.parseInt(holdingsRoot.dataset.cryptoProfileId, 10)} />, holdingsRoot);
  }

  const transactionsRoot = document.getElementById('crypto-profile-transactions');
  if (transactionsRoot) {
    render(<CryptoTransactions profileId={Number.parseInt(transactionsRoot.dataset.cryptoProfileId, 10)} />, transactionsRoot);
  }

  const nftsRoot = document.getElementById('crypto-profile-nfts');
  if (nftsRoot) {
    render(<CryptoNfts profileId={Number.parseInt(nftsRoot.dataset.cryptoProfileId, 10)} />, nftsRoot);
  }
}

window.InstantClick.on('change', () => {
  loadElement();
});

loadElement();
