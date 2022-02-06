# Mono Custodian Dao

<h1>What does this smart contract do ?</h1>

###### send to mono
sendToMono() function : copy paste mano's owner's address and set a value with ether for your investment. Note that this method works only for one address.
That means a person who want to use sendToMono function a few time must have a few address. 1 address only send ether once. Change or add your addresses.

###### send to artist
sendToArtist() function : This is also only owner's function. Send ether to artist but if payedCost(which users pay) + 0.1 ether(profit --can change later) and expectedCost(a cost for artists wanted -- if owner wants to change can use setExpectedCost() function) must be equal owners amount to transfer. Also if you want to use this function first unlock to contract with use unlock function(only owner again).


just copy and paste this code.[ready to try ?](https://remix.ethereum.org)




