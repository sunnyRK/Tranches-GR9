
const { expect } = require("chai");
const { BigNumber, Wallet } = require("ethers");
const { formatEther, parseEther } =require('@ethersproject/units')
const usdcABI = require('../abis/usdc.json');
const barnBridgeUsdcABI = require('../abis/barnBridgeUsdc.json');
const { ethers } = require("hardhat");

// Mainnet Fork and test case for mainnet with hardhat network by impersonate account from mainnet

describe("deployed Contract", function() {
  it("Test", async function() {
    const accounts = await ethers.getSigners();

    const accountToImpersonate = '0xa1d8d972560c2f8144af871db508f0b0b10a3fbf'
    const usdcAddress = '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48'
    const smartYieldBarnBridgeAddress = '0x4B8d90D68F26DEF303Dcb6CFc9b63A1aAEC15840'

    await hre.network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [accountToImpersonate]}
    )

    let signer = await ethers.provider.getSigner(accountToImpersonate)
    let usdcContract = new ethers.Contract(usdcAddress, usdcABI, signer)

    await usdcContract.transfer(accounts[0].address, usdcContract.balanceOf(accountToImpersonate))

    signer = await ethers.provider.getSigner(accounts[0].address)
    usdcContract = new ethers.Contract(usdcAddress, usdcABI, signer)
    // const signer2 = await ethers.provider.getSigner(accounts[0].address)
    
    const IdleBarnBridge = await ethers.getContractFactory('IdleBarnBridge', signer);
    const IdleBarnBridge_Instance = await IdleBarnBridge.deploy();
    console.log('IdleBarnBridge_Instance: ', IdleBarnBridge_Instance.address);

    let barnBridgeUsdcContract = new ethers.Contract(smartYieldBarnBridgeAddress, barnBridgeUsdcABI, signer)
    console.log('barnBridgeUsdcContract.address: ', barnBridgeUsdcContract.address)

    await IdleBarnBridge_Instance.initialize(
        barnBridgeUsdcContract.address, 
        accounts[0].address,
        usdcAddress
    )

    await usdcContract.approve(barnBridgeUsdcContract.address, '1000000000000000000000000000000000')
    await usdcContract.transfer(IdleBarnBridge_Instance.address, '10000000')

    const bal4 = await usdcContract.balanceOf(IdleBarnBridge_Instance.address)
    console.log('IdleBarnBridge_Instance.address-bal4: ', bal4.toString())

    const bal5 = await barnBridgeUsdcContract.balanceOf(IdleBarnBridge_Instance.address)
    console.log('barnBridgeUsdcContract.address-bal5: ', bal5.toString())

    await IdleBarnBridge_Instance.mint() //// Mint Tokens or BuyTokens from BarnBridge
    
    const bal6 = await usdcContract.balanceOf(IdleBarnBridge_Instance.address)
    console.log('IdleBarnBridge_Instance.address-bal6: ', bal6.toString())

    const bal61 = await barnBridgeUsdcContract.balanceOf(accounts[0].address)
    console.log('barnBridgeUsdcContract.address-bal61: ', bal61.toString())

    await barnBridgeUsdcContract.transfer(IdleBarnBridge_Instance.address, bal61)

    // barnBridgeUsdcContract = new ethers.Contract(smartYieldBarnBridgeAddress, barnBridgeUsdcABI, signer)

    const bal7 = await barnBridgeUsdcContract.balanceOf(IdleBarnBridge_Instance.address)
    console.log('barnBridgeUsdcContract.address-bal7: ', bal7.toString())

    await IdleBarnBridge_Instance.redeem(IdleBarnBridge_Instance.address) //// Idle Redeem or SellTokens from BarnBeidge 

    const bal8 = await usdcContract.balanceOf(IdleBarnBridge_Instance.address)
    console.log('IdleBarnBridge_Instance.address-bal8: ', bal8.toString())
    
    const bal9 = await barnBridgeUsdcContract.balanceOf(IdleBarnBridge_Instance.address)
    console.log('barnBridgeUsdcContract.address-bal9: ', bal9.toString())

  });
})