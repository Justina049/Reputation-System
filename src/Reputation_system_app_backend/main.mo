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

  // Get Reputation Score (With Decay Applied)
  public query func getReputation(user: Principal) : async Nat {
    let currentTime = Time.now();
    let lastSeen = switch (lastActiveTime.get(user)) {
      case (?time) time;
      case null Time.now();
    };

    let monthsInactive = (currentTime - lastSeen) / (30 * 24 * 60 * 60 * 1_000_000_000);
    var reputation = switch (reputationScores.get(user)) {
      case (?score) score;
      case null 0;
    };

    if (monthsInactive > 0) {
      let monthsInactiveNat = if (monthsInactive >= 0) Int.abs(monthsInactive) else 0;
      let decayAmount = reputation * decayRate * monthsInactiveNat / 100;
      reputation := if (decayAmount >= reputation) 0 else reputation - decayAmount;
    };

    return reputation;
  };

  // Weighted Reputation System (High-Rep Users Have More Influence)
  public shared(msg) func giveReputation(to: Principal) : async Text {
    let caller = msg.caller;

    switch (verifiedUsers.get(caller), verifiedUsers.get(to)) {
      case (?true, ?true) { /* Both users must be verified, continue */ };
      case (_, _) { return "Both users must be verified.";};
    };

    if (Principal.equal(caller, to)) {
      return "You cannot give reputation to yourself!";
    };

    switch (ratingHistory.get((caller, to))) {
      case (?_) { return "You have already rated this user!"; };
      case (null) { /* First rating, continue */ }; 
    };

    let callerReputation = switch (reputationScores.get(caller)) {
        case (?score) score;
        case null 0;
   };

   var currentReputation = switch (reputationScores.get(to)) {
    case (?score) score;
    case null 0;
   };

   let weight = if (callerReputation > weightTreshold) 2 else 1;
   reputationScores.put(to, currentReputation + weight);
   ratingHistory.put((caller, to), weight);

   lastActiveTime.put(caller, Time.now());

   return "Reputation updated successfully!"; 
  };






}