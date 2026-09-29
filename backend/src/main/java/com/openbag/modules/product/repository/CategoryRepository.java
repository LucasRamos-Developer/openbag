package com.openbag.modules.product.repository;

import com.openbag.platform.web.exception.ResourceNotFoundException;
import com.openbag.modules.product.entity.Category;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CategoryRepository extends JpaRepository<Category, Long> {

    @Query("SELECT c FROM Category c WHERE c.isActive = true ORDER BY c.name")
    List<Category> findAllActive();
    
    boolean existsByName(String name);

    /** Busca as categorias pelos ids; falha se alguma não existir */
    default List<Category> findAllByIdOrThrow(List<Long> ids) {
        List<Category> categories = findAllById(ids);
        if (categories.size() != ids.stream().distinct().count()) {
            throw new ResourceNotFoundException("Uma ou mais categorias não foram encontradas");
        }
        return categories;
    }
}
