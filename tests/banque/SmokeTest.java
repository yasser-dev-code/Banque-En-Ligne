package banque;

import banque.controleurs.AuthControleur;
import banque.controleurs.VirementControleur;
import banque.modele.abstractions.CompteBancaire;
import banque.modele.operations.Virement;
import banque.modele.utilisateur.Client;

public final class SmokeTest {
    private SmokeTest() {}

    public static void main(String[] args) throws Exception {
        AuthControleur auth = new AuthControleur();
        check(!auth.authentifier("demo.client@example.test", "incorrect"),
                "Invalid credentials must be rejected");
        check(auth.authentifier("demo.client@example.test", "demo1234"),
                "Demo client authentication failed");

        Client client = auth.getClientConnecte();
        check(client != null, "Authenticated client is missing");
        check(client.getComptes().size() == 2, "Demo client should have two accounts");

        CompteBancaire source = client.getComptes().get(0);
        CompteBancaire destination = client.getComptes().get(1);
        double sourceBefore = source.getSolde();
        double destinationBefore = destination.getSolde();

        VirementControleur transfers = new VirementControleur();
        Virement internal = transfers.creerVirement(source, destination, 50.0, "Test interne");
        transfers.executerVirement(internal);
        check(internal.isExecute(), "Internal transfer was not marked as executed");
        checkClose(sourceBefore - 50.0, source.getSolde(), "Internal transfer source balance");
        checkClose(destinationBefore + 50.0, destination.getSolde(), "Internal transfer destination balance");

        double externalBefore = source.getSolde();
        source.effectuerVirementExterne(
                "FR7630002005500000000000000", "Destinataire Demo", 25.0, "Test externe");
        checkClose(externalBefore - 26.5, source.getSolde(), "External transfer balance and fee");
        check(!source.getHistorique().isEmpty(), "Transaction history should not be empty");

        auth.deconnecter();
        check(!auth.estConnecte(), "Logout failed");
        System.out.println("Smoke tests passed: authentication, accounts, transfers, history, logout.");
    }

    private static void check(boolean condition, String message) {
        if (!condition) { throw new AssertionError(message); }
    }

    private static void checkClose(double expected, double actual, String label) {
        if (Math.abs(expected - actual) > 0.0001) {
            throw new AssertionError(label + ": expected " + expected + ", got " + actual);
        }
    }
}
