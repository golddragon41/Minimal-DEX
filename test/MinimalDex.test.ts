
import { expect } from "chai";
import { ethers } from "hardhat";
import { MinimalDex, ERC20, Pair } from "../typechain-types";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";

describe("MinimalDex", function () {
    let minimalDex: MinimalDex;
    let token0: ERC20;
    let token1: ERC20;
    let token0Address: string;
    let token1Address: string;
    let owner: SignerWithAddress, addr1: SignerWithAddress, addr2: SignerWithAddress;

    before(async function () {
        [owner, addr1, addr2] = await ethers.getSigners();

        // Deploy mock ERC20 tokens
        const Token = await ethers.getContractFactory("ERC20");
        token0 = (await Token.deploy()) as ERC20;
        token1 = (await Token.deploy()) as ERC20;

        await token0.waitForDeployment();
        await token1.waitForDeployment();

        token0Address = await token0.getAddress();
        token1Address = await token1.getAddress();
        // Deploy MinimalDex contract
        const MinimalDex = await ethers.getContractFactory("MinimalDex");
        minimalDex = (await MinimalDex.deploy(owner.address)) as MinimalDex;
        await minimalDex.waitForDeployment();
    });

    describe("Factory", function () {
        it("Should deploy with the correct owner", async function () {
            expect(await minimalDex.owner()).to.equal(owner.address);
        });
    
        it("Should create a pair successfully", async function () {
            await expect(minimalDex.createPair(token0Address, token1Address))
                .to.emit(minimalDex, "PairCreated");
    
            const pairAddress = await minimalDex.getPair(token0Address, token1Address);
            expect(pairAddress).to.not.equal(ethers.ZeroAddress);
        });
    
        it("Should prevent creating a pair with identical tokens", async function () {
            await expect(minimalDex.createPair(token0Address, token0Address))
                .to.be.revertedWithCustomError(minimalDex, "IdenticalTokenAddresses");
        });
    
        it("Should prevent creating a duplicate pair", async function () {
            await expect(minimalDex.createPair(token0Address, token1Address))
                .to.be.revertedWithCustomError(minimalDex, "PairAlreadyExists");
        });
    });

    describe("Functionality", function () {
        let pair: Pair;
        let pairAddress: string;
        before(async function () {
            await token0.connect(addr1).mint(ethers.parseEther("10000"));
            await token1.connect(addr1).mint(ethers.parseEther("10000"));

            pairAddress = await minimalDex.getPair(token0Address, token1Address);
            pair = (await ethers.getContractFactory("Pair")).attach(pairAddress) as Pair;
        });

        it("should allow adding liquidity", async function () {
            await token0.connect(addr1).approve(pairAddress, ethers.parseEther("100"));
            await token1.connect(addr1).approve(pairAddress, ethers.parseEther("100"));
    
            await expect(pair.connect(addr1).addLiquidity(ethers.parseEther("10"), ethers.parseEther("10")))
                .to.emit(pair, "Mint")
                .withArgs(addr1.address, ethers.parseEther("10"), ethers.parseEther("10"), anyValue);
        });

        it("should not allow adding empty liquidity", async function () {
            await expect(pair.connect(addr1).addLiquidity(ethers.parseEther("0"), ethers.parseEther("0")))
                .to.be.revertedWithCustomError(pair, "InsufficientInputAmount");
        });
    
        it("should allow removing liquidity", async function () {
            await token0.connect(addr1).approve(pairAddress, ethers.parseEther("100"));
            await token1.connect(addr1).approve(pairAddress, ethers.parseEther("100"));
            await pair.connect(addr1).addLiquidity(ethers.parseEther("10"), ethers.parseEther("10"));
    
            const liquidity = await pair.balanceOf(addr1.address);
            await pair.connect(addr1).approve(pairAddress, liquidity);
            await expect(pair.connect(addr1).removeLiquidity(liquidity)).to.emit(pair, "Burn");
        });

        it("should fail to remove liquidity with insufficient balance", async function () {
            const liquidity = ethers.parseEther("100");
            await expect(pair.connect(addr1).removeLiquidity(liquidity))
                .to.be.revertedWithCustomError(pair, "InsufficientLiquidity");
        });
    
        it("should perform a swap correctly", async function () {
            await token0.connect(addr1).approve(pairAddress, ethers.parseEther("100"));
            await token1.connect(addr1).approve(pairAddress, ethers.parseEther("100"));
            await pair.connect(addr1).addLiquidity(ethers.parseEther("50"), ethers.parseEther("50"));
    
            // mint to user1
            await token0.connect(addr2).mint( ethers.parseEther("10"));
            await token0.connect(addr2).approve(pairAddress, ethers.parseEther("10"));
    
            await expect(pair.connect(addr2).swap(ethers.parseEther("10"), 0)).to.emit(pair, "Swap");
        });

        it("should fail to swap with invalid input amounts", async function () {
            await expect(pair.connect(addr2).swap(ethers.parseEther("10"), ethers.parseEther("10")))
                .to.be.revertedWithCustomError(pair, "InvalidInputAmount");
        });

        it("should fail to swap with insufficient input amounts", async function () {
            await expect(pair.connect(addr2).swap(ethers.parseEther("0"), ethers.parseEther("0")))
                .to.be.revertedWithCustomError(pair, "InsufficientInputAmount");
        });
    });
});
