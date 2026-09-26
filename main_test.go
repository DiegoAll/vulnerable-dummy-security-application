package main

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestHealthHandler(t *testing.T) {
	req, err := http.NewRequest("GET", "/health", nil)
	if err != nil {
		t.Fatalf("No se pudo crear la petición HTTP: %v", err)
	}

	rr := httptest.NewRecorder()
	handler := http.HandlerFunc(HealthHandler)

	handler.ServeHTTP(rr, req)

	if status := rr.Code; status != http.StatusOK {
		t.Errorf("Código de estado incorrecto: obtuvo %v se esperaba %v", status, http.StatusOK)
	}

	var resp Response
	if err := json.Unmarshal(rr.Body.Bytes(), &resp); err != nil {
		t.Fatalf("Respuesta no es JSON válido: %v", err)
	}

	if resp.Status != "ok" {
		t.Errorf("Estatus inesperado: obtuvo %v se esperaba 'ok'", resp.Status)
	}
}
