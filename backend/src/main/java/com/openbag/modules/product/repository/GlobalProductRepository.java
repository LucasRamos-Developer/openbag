package com.openbag.modules.product.repository;

import com.openbag.modules.product.entity.Category;
import com.openbag.modules.product.entity.GlobalProduct;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface GlobalProductRepository extends JpaRepository<GlobalProduct, Long> {

    /**
     * Buscar produto global por código de barras
     */
    Optional<GlobalProduct> findByBarcode(String barcode);

    /**
     * Buscar produto global por código de barras (apenas ativos)
     */
    Optional<GlobalProduct> findByBarcodeAndIsActiveTrue(String barcode);

    /**
     * Buscar por nome (contém texto, case-insensitive)
     */
    @Query("SELECT gp FROM GlobalProduct gp WHERE LOWER(gp.name) LIKE LOWER(CONCAT('%', :name, '%')) " +
           "AND gp.isActive = true")
    List<GlobalProduct> searchByName(@Param("name") String name);

    /**
     * Buscar por categoria
     */
    List<GlobalProduct> findByCategoryAndIsActiveTrue(Category category);

    /**
     * Buscar por marca
     */
    @Query("SELECT gp FROM GlobalProduct gp WHERE LOWER(gp.brand) LIKE LOWER(CONCAT('%', :brand, '%')) " +
           "AND gp.isActive = true")
    List<GlobalProduct> searchByBrand(@Param("brand") String brand);

    /**
     * Listar todos os produtos globais ativos
     */
    List<GlobalProduct> findByIsActiveTrue();

    /**
     * Verificar se código de barras já existe
     */
    boolean existsByBarcode(String barcode);
}
