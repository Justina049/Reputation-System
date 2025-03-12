import Principal "mo:base/Principal";
import Nat "mo:base/Nat";
import Time "mo:base/Time";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
// import Nat64 "mo:base/Nat64";
import Int "mo:base/Int";
import Text "mo:base/Text";


// actor ReputationSystem {

//   stable var reputationStorage: [(Principal, Nat)] = [];
//   stable var tokenStorage: [(Principal, Nat)] = [];
  
//   var reputationScores = HashMap.HashMap<Principal, Nat>(10, Principal.equal, Principal.hash);
//   var tokenBalances = HashMap.HashMap<Principal, Nat>(10, Principal.equal, Principal.hash);

//   // Function to check a user's reputation score
//   public query func getReputation(user: Principal) : async Nat {
//   switch (reputationScores.get(user)) {
//     case (?score) score;
//     case null 0;
//   }
//   };

//   public func giveReputation(to: Principal) : async Text {
//     let caller = Principal.fromActor(ReputationSystem);

//     if (caller == to ) {
//       return "You cannot give reputation to yourself!";
//     };
//     let currentScore = switch (reputationScores.get(to)) {
//       case (?score) score;
//       case null 0;
//     };

//     reputationScores.put(to, currentScore + 1);
//     return "Reputation successfully given!";
//   }
  
// };



actor ReputationSystem {
  let admin = Principal.fromActor(ReputationSystem);

  // Stable storage for persistence across upgrades
  stable var reputationStorage: [(Principal, Nat)] = [];
  stable var lastActiveTimeStorage: [(Principal, Time.Time)] = [];
  stable var verifiedUsersStorage: [(Principal, Bool)] = [];
  stable var ratingHistoryStorage: [((Principal, Principal), Nat)] = [];

  // Runtime HashMaps
  var reputationScores = HashMap.HashMap<Principal, Nat>(10, Principal.equal, Principal.hash);
  var lastActiveTime = HashMap.HashMap<Principal, Time.Time>(10, Principal.equal, Principal.hash);
  var verifiedUsers = HashMap.HashMap<Principal, Bool>(10, Principal.equal, Principal.hash);
  var ratingHistory = HashMap.HashMap<(Principal, Principal), Nat>(10, 
    func(a, b) {Principal.equal(a.0, b.0) and Principal.equal(a.1, b.1) },
    func (k) {Principal.hash(k.0) + Principal.hash(k.1)}
  );

  let decayRate = 5;
  let weightTreshold = 10;

  public func init() {
    if (reputationStorage.size () > 0) {
      reputationScores :=HashMap.fromIter<Principal, Nat>(
        reputationStorage.vals(), 10, Principal.equal, Principal.hash
      );
    };

    if (lastActiveTimeStorage.size() > 0) {
      lastActiveTime := HashMap.fromIter<Principal, Time.Time>(
        lastActiveTimeStorage.vals(), 10, Principal.equal, Principal.hash
      );
    };

    if (verifiedUsersStorage.size() > 0) {
      verifiedUsers := HashMap.fromIter<Principal, Bool>(
        verifiedUsersStorage.vals(), 10, Principal.equal, Principal.hash
      );
    };

    if (ratingHistoryStorage.size() > 0) {
      ratingHistory := HashMap.fromIter<(Principal, Principal), Nat>(
        ratingHistoryStorage.vals(), 10, 
        func(a, b) {Principal.equal(a.0, b.0) and Principal.equal(a.1, b.1) },
        func (k) {Principal.hash(k.0) + Principal.hash(k.1)}
      );
    };
  };

  system func preupgrade() {
    reputationStorage := Iter.toArray(reputationScores.entries());
    lastActiveTimeStorage := Iter.toArray(lastActiveTime.entries());
    verifiedUsersStorage := Iter.toArray(verifiedUsers.entries());
    ratingHistoryStorage := Iter.toArray(ratingHistory.entries());
  };

  // Only Admins Can Verify Users
  public shared(msg) func verifiedUser(user: Principal) : async Text {
    if (not Principal.equal(msg.caller, admin)) {
      return "Unauthorized: Only Admins can verify users!";
    };
    verifiedUsers.put(user, true);
    return "User successfully verified!";
  };

  




}