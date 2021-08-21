// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

// Import the UsingWitnet library that enables interacting with Witnet
import "witnet-ethereum-bridge/contracts/UsingWitnet.sol";
// Import the YouTube request that we created before
import "./requests/YouTube.sol";

// Your contract needs to inherit from UsingWitnet
contract ViewCountOracle is UsingWitnet {
  using Witnet for Witnet.Result;

  // The public viewCount point
  uint64 public lastViewCount;

  // Stores the ID of the last Witnet request
  uint256 public lastRequestId;

  // Stores the timestamp of the last time the viewcount was updated
  uint256 public timestamp;

  // Tells if an update has been requested but not yet completed
  bool public pending;

  // The Witnet request object, is set in the constructor
  Request public request;

  // Emits when viewCount is updated
  event ViewCountUpdated(uint64);

  // Emits when found an error decoding request result
  event ResultError(string);

  bytes public query;

  // This constructor does a nifty trick to tell the `UsingWitnet` library where
  // to find the Witnet contracts on whatever Ethereum network you use.
  constructor (address _wrb, string memory _id) UsingWitnet(_wrb) {
    query = bytes(abi.encodePacked(
      hex"0a6b08ece0fd88061245123368747470733a2f2f6170692d6d6964646c6577617265732e76657263656c2e6170702f6170692f796f75747562652f",
      _id,
      hex"1a0e83187782186765766965777318731a0d0a0908051205fa3fc000001003220d0a0908051205fa3fc00000100310c0843d186420e80728333080c8afa025"
    ));

    // Instantiate the Witnet request
    request = new YouTubeRequest(query);
  }

  /**
  * @notice Sends `request` to the WitnetRequestBoard.
  * @dev This method will only succeed if `pending` is 0.
  **/
  function requestUpdate() public payable {
    require(!pending, "Complete pending request before requesting a new one");

    // Send the request to Witnet and store the ID for later retrieval of the result
    // The `witnetPostRequest` method comes with `UsingWitnet`
    lastRequestId = witnetPostRequest(request);

    // Signal that there is already a pending request
    pending = true;
  }

  /**
  * @notice Reads the result, if ready, from the WitnetRequestBoard.
  * @dev The `witnetRequestAccepted` modifier comes with `UsingWitnet` and allows to
  * protect your methods from being called before the request has been successfully
  * relayed into Witnet.
  **/
  function completeUpdate() public witnetRequestResolved(lastRequestId) {
    require(pending, "There is no pending update.");

    // Read the result of the Witnet request
    // The `witnetReadResult` method comes with `UsingWitnet`
    Witnet.Result memory result = witnetReadResult(lastRequestId);

    // If the Witnet request succeeded, decode the result and update viewCount
    // If it failed, revert the transaction with a pretty-printed error message
    if (result.isOk()) {
      lastViewCount = result.asUint64();
      timestamp = block.timestamp;
      emit ViewCountUpdated(lastViewCount);
    } else {
      string memory errorMessage;

      // Try to read the value as an error message, catch error bytes if read fails
      try result.asErrorMessage() returns (Witnet.ErrorCodes, string memory e) {
        errorMessage = e;
      }
      catch (bytes memory errorBytes){
        errorMessage = string(errorBytes);
      }
      emit ResultError(errorMessage);
    }

    // In any case, set `pending` to false so a new update can be requested
    pending = false;
  }
}
