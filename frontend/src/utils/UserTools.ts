import { DecodedToken } from "./types";

interface RequestObj {
  url: string;
  method: string;
  headers: Object;
  data: Object;
  objInfo: Object;
}

export default class UsersTools {
  token: string | null = null;
  decodedToken: DecodedToken | null = null;
  role: string | null = null;
  user_id: number | null = null;
  team_id: number | null = null;
  isGoogleUser: string | boolean | undefined = false;
  requestOffline: Array<RequestObj> = [];

  constructor() {
    window.addEventListener('online', this.handleOnline);
    // window.addEventListener('offline', this.handleOffline);
    
    this.requestOffline = this.loadOfflineRequests();
  }

  // Détecter l'état de connexion en ligne
  isOnline = (): boolean => {
    return navigator.onLine;
  };

  // Gestion du retour en ligne
  handleOnline = () => {
    console.log('Connexion rétablie, traitement des requêtes en attente...');
    this.processQueuedRequests();
  };

  isLogin = () => !!this.token;

  isAdmin = () => this.role === "admin";

  isGeneralManager = () => this.role === "general_manager";

  isManager = () => this.role === "manager";

  isEmployee = () => this.role === "employee";

  addOfflineRequest = (request: RequestObj) => {
    if (!this.isOnline()) {
      this.requestOffline.push(request);
      this.saveOfflineRequests();
    }
  };

  // Sauvegarde `requestOffline` dans localStorage
  private saveOfflineRequests = () => {
    localStorage.setItem('offlineRequests', JSON.stringify(this.requestOffline));
  };

  // Charge les requêtes hors ligne depuis localStorage
  private loadOfflineRequests = (): Array<RequestObj> => {
    const cachedRequests = localStorage.getItem('offlineRequests');
    return cachedRequests ? JSON.parse(cachedRequests) : [];
  };

  private sendRequest = async (request: RequestObj) => {
    if (request.method === "GET") { return; }

    try {
      const headers: Record<string, string> = request.headers as Record<string, string>;

      // Vérification d'existence pour POST et DELETE
      if (request.method === "POST" || request.method === "DELETE") {
        const existenceCheckUrl = request.method === "POST"
          ? `${request.url}/${request.objInfo}`
          : request.url;

        const verifyExistance = await fetch(existenceCheckUrl, {
          method: "GET",
          headers: headers,
        });

        // Annuler le POST si l'objet existe déjà
        if (verifyExistance.ok && request.method === "POST") {
          console.log("L'objet existe déjà, annulation de la requête POST.");
          return;
        }

        // Annuler le DELETE si l'objet n'existe pas
        if (verifyExistance.status === 404 && request.method === "DELETE") {
          console.log("L'objet n'existe pas, annulation de la requête DELETE.");
          return;
        }
      }

      const response = await fetch(request.url, {
        method: request.method,
        headers: headers,
        body: request.method === "DELETE" ? null : JSON.stringify(request.data),
      });

      // Vérifier si la réponse est OK
      if (!response.ok) {
        throw new Error(`Erreur HTTP: ${response.status}`);
      }

      // Si la réponse est en JSON, la parser
      const data = await response.json();
      return data;
      
    } catch (error) {
      console.error('Erreur lors de l\'envoi de la requête:', error);
      throw error;
    }
  };

  private processQueuedRequests = async () => {
    // Verifier l'etat de connexion
    if (!this.isOnline()) {
      console.log('Connexion perdue, requêtes en attente enregistrées');
      return;
    }

    while (this.requestOffline.length > 0) {
      const request = this.requestOffline.shift();
      if (request && this.isOnline()) {
        try {
          const response = await this.sendRequest(request);
          console.log('Requête traitée avec succès:', response);
        } catch (error) {
          console.error('Erreur lors de l\'envoi de la requête:', error);
          this.requestOffline.unshift(request);
          this.saveOfflineRequests();
          break;
        }
      }
    }

    // Sauvegarder l'état final de `requestOffline`
    this.saveOfflineRequests();
  };

  removeListeners = () => {
    window.removeEventListener('online', this.handleOnline);
  };
}
