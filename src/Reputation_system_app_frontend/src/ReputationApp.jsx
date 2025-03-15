import React, { useState, useEffect } from 'react';
import { AuthClient } from "@dfinity/auth-client";
import { HttpAgent } from "@dfinity/agent";
import { Principal } from "@dfinity/principal";
import { createActor } from "../../declarations/Reputation_system_app_backend";

function ReputationApp() {
  const [userPrincipal, setUserPrincipal] = useState(null);
  const [targetPrincipal, setTargetPrincipal] = useState("");
  const [message, setMessage] = useState("");
  const [actor, setActor] = useState(null);
  const [isLoading, setIsLoading] = useState(false);
  const [reportTarget, setReportTarget] = useState("");
  const [reportMessage, setReportMessage] = useState("");
  
  // Check if user is already authenticated on component mount
  useEffect(() => {
    const checkAuth = async () => {
      const authClient = await AuthClient.create();
      if (await authClient.isAuthenticated()) {
        const identity = authClient.getIdentity();
        setUserPrincipal(identity.getPrincipal().toString());
        
        const agent = new HttpAgent({ identity });
        
        // Fetch root key for local development
        if (process.env.DFX_NETWORK !== "ic") {
          await agent.fetchRootKey().catch(err => {
            console.warn("Unable to fetch root key. Check to ensure that your local replica is running");
            console.error(err);
          });
        }
        
        // const canisterId = process.env.CANISTER_ID_REPUTATION_SYSTEM_APP_BACKEND;
        const canisterId = 'cuj6u-c4aaa-aaaaa-qaajq-cai'; // Your backend canister ID
        const newActor = createActor(canisterId, { agentOptions: { identity } });
        setActor(newActor);
      }
    };
    
    checkAuth();
  }, []);
  
  // Login function
  const login = async () => {
    setIsLoading(true);
    try {
      const authClient = await AuthClient.create();
      
      // Start the login process and wait for it to finish
      await new Promise((resolve, reject) => {
        authClient.login({
          identityProvider: process.env.DFX_NETWORK === "ic" 
            ? "https://identity.ic0.app/#authorize"
            : `http://localhost:4943?canisterId=rdmx6-jaaaa-aaaaa-aaadq-cai#authorize`,
          onSuccess: resolve,
          onError: reject
        });
      });
      
      // At this point we're authenticated
      const identity = authClient.getIdentity();
      setUserPrincipal(identity.getPrincipal().toString());
      
      // Create an agent with the identity
      const agent = new HttpAgent({ identity });
      
      // Fetch root key for local development
      if (process.env.DFX_NETWORK !== "ic") {
        await agent.fetchRootKey().catch(err => {
          console.warn("Unable to fetch root key. Check to ensure that your local replica is running");
          console.error(err);
        });
      }
      // Get the canister ID and create an actor
      // const canisterId = process.env.CANISTER_ID_REPUTATION_SYSTEM_APP_BACKEND;
      const canisterId = 'cuj6u-c4aaa-aaaaa-qaajq-cai'; // Your backend canister ID
      const newActor = createActor(canisterId, { agentOptions: { identity } });
      setActor(newActor);
    } catch (error) {
      console.error("Login failed:", error);
      setMessage("Login failed: " + error.message);
    } finally {
      setIsLoading(false);
    }
  };
  
  // Logout function
  const logout = async () => {
    const authClient = await AuthClient.create();
    await authClient.logout();
    setUserPrincipal(null);
    setActor(null);
    setMessage("");
  };
  
  // Call your canister's giveReputation function
  const rateUser = async () => {
    if (!actor) {
      setMessage("Error: Not authenticated");
      return;
    }
    
    if (!targetPrincipal) {
      setMessage("Error: Please enter a principal to rate");
      return;
    }
    
    setIsLoading(true);
    try {
      // Validate the principal format
      const principal = Principal.fromText(targetPrincipal);
      const result = await actor.giveReputation(principal);
      setMessage(result);
    } catch (error) {
      console.error("Rating failed:", error);
      setMessage("Error: " + error.message);
    } finally {
      setIsLoading(false);
    }
  };
  // Report fake rating function
  const reportFakeRating = async () => {
    if (!actor) {
      setReportMessage("Error: Not authenticated");
      return;
    }
    
    if (!reportTarget) {
      setReportMessage("Error: Please enter a principal to report");
      return;
    }
    
    setIsLoading(true);
    try {
      // Validate the principal format
      const principal = Principal.fromText(reportTarget);
      const result = await actor.reportFakeRating(principal, userPrincipal);
      setReportMessage(result);
    } catch (error) {
      console.error("Reporting failed:", error);
      setReportMessage("Error: " + error.message);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="reputation-app">
      <h1>Reputation System</h1>
      
      {userPrincipal ? (
        <div className="authenticated-view">
          <div className="user-info">
            <p>Your Principal: <span className="principal-id">{userPrincipal}</span></p>
            <button onClick={logout} className="logout-button">Logout</button>
          </div>
          
          <div className="rating-form">
            <h2>Rate a User</h2>
            <input 
              value={targetPrincipal}
              onChange={(e) => setTargetPrincipal(e.target.value)}
              placeholder="Enter principal to rate"
              disabled={isLoading}
            />
            <button 
              onClick={rateUser} 
              disabled={isLoading || !targetPrincipal}
              className="rate-button"
            >
              {isLoading ? "Processing..." : "Give Reputation"}
            </button>
          </div>
          
          {message && <div className="message">{message}</div>}
          <div className="report-form">
            <h2>Report Fake Rating</h2>
            <p>If you believe a user has received fake ratings, you can report them for review.</p>
            <input 
              value={reportTarget}
              onChange={(e) => setReportTarget(e.target.value)}
              placeholder="Enter principal to report"
              disabled={isLoading}
            />
            <button 
              onClick={reportFakeRating} 
              disabled={isLoading || !reportTarget}
              className="report-button"
            >
              {isLoading ? "Processing..." : "Report Fake Rating"}
            </button>
            {reportMessage && <div className="message">{reportMessage}</div>}
          </div>
          <div className="verification-status">
            <h2>Verification Status</h2>
            <p>Your verification status determines what actions you can take in the system.</p>
            <button
              onClick={async () => {
                try {
                  isVerified = await actor.isUserVerified(Principal.fromText(userPrincipal));
                  setMessage(isVerified ? "You are verified!" : "You are not verified yet.");
                } catch (error) {
                  setMessage("Error checking verification status: " + error.message);
                }
              }}
              className="check-status-button"
            >
              Check My Verification Status
            </button>
          </div>
        </div>
        
      ) : (
        <div className="login-view">
          <p>Please login with Internet Identity to use the Reputation System</p>
          <button 
            onClick={login} 
            disabled={isLoading}
            className="login-button"
          >
            {isLoading ? "Connecting..." : "Login with Internet Identity"}
          </button>
          {message && <div className="message">{message}</div>}
        </div>
      )}
    </div>
  );
}

export default ReputationApp;