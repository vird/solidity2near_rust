# solidity2near_rust
solidity to NEAR protocol rust translator

## recommended software requirements

    # install nvm https://github.com/nvm-sh/nvm 
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh | bash
    source ~/.bashrc
    # node install
    nvm i 6.6
    npm i -g iced-coffee-script

## how to use
NOTE there is no cli tool for now. But workaround is present.

    # no cli tool for now
    # clone this repo (one time)
    git clone https://github.com/vird/solidity2near_rust
    cd solidity2near_rust
    npm i
    # how to use
    ./test_translate.coffee <contract.sol>
