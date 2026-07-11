package com.zhiyi.module.item.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.zhiyi.common.BusinessException;
import com.zhiyi.common.ResultCode;
import com.zhiyi.module.admin.entity.ViolationReport;
import com.zhiyi.module.admin.mapper.ViolationReportMapper;
import com.zhiyi.module.item.dto.PublishItemDTO;
import com.zhiyi.module.item.entity.Category;
import com.zhiyi.module.item.entity.Item;
import com.zhiyi.module.item.mapper.CategoryMapper;
import com.zhiyi.module.item.mapper.ItemMapper;
import com.zhiyi.module.item.vo.ItemCardVO;
import com.zhiyi.module.item.vo.UploadImageVO;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.math.BigDecimal;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.UUID;

/**
 * 模块二：商品发布、图片上传与本地规则审核/打标。
 */
@Service
@RequiredArgsConstructor
public class ItemPublishService {

    private static final long MAX_IMAGE_BYTES = 5L * 1024 * 1024;
    private static final DateTimeFormatter DAY_FORMATTER = DateTimeFormatter.BASIC_ISO_DATE;
    private static final List<String> VIOLATION_KEYWORDS = List.of(
            "代写", "代考", "替考", "论文代", "枪支", "毒品", "管制刀具", "开锁", "诈骗", "博彩", "外挂"
    );

    private final ItemMapper itemMapper;
    private final CategoryMapper categoryMapper;
    private final ViolationReportMapper violationReportMapper;
    private final MarketplaceService marketplaceService;
    private final ObjectMapper objectMapper;

    @Value("${zhiyi.upload-path:./uploads}")
    private String uploadPath;

    public UploadImageVO uploadImage(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new BusinessException(ResultCode.BAD_REQUEST, "请选择要上传的图片");
        }
        if (file.getSize() > MAX_IMAGE_BYTES) {
            throw new BusinessException(ResultCode.BAD_REQUEST, "单张图片不能超过5MB");
        }
        String extension = extensionOf(file.getOriginalFilename(), file.getContentType());
        String day = LocalDate.now().format(DAY_FORMATTER);
        String filename = UUID.randomUUID().toString().replace("-", "") + "." + extension;
        Path targetDir = Path.of(uploadPath, "items", day).toAbsolutePath().normalize();
        Path target = targetDir.resolve(filename).normalize();
        if (!target.startsWith(targetDir)) {
            throw new BusinessException(ResultCode.BAD_REQUEST, "文件名非法");
        }
        try {
            Files.createDirectories(targetDir);
            Files.copy(file.getInputStream(), target, StandardCopyOption.REPLACE_EXISTING);
        } catch (IOException e) {
            throw new BusinessException(ResultCode.SERVER_ERROR, "图片保存失败");
        }
        return new UploadImageVO("/uploads/items/" + day + "/" + filename);
    }

    @Transactional
    public ItemCardVO publish(Long publisherId, PublishItemDTO dto) {
        Category category = categoryMapper.selectById(dto.getCategoryId());
        if (category == null) {
            throw new BusinessException(ResultCode.NOT_FOUND, "商品分类不存在");
        }
        validateImages(dto.getImages());

        ReviewResult review = review(dto, category);
        if (review.violation()) {
            saveViolationReport(publisherId, dto, review, false);
            throw new BusinessException(ResultCode.AI_VIOLATION, review.reason());
        }

        Item item = new Item();
        item.setPublisherId(publisherId);
        item.setType(dto.getType());
        item.setTitle(dto.getTitle().trim());
        item.setDescription(dto.getDescription().trim());
        item.setCategoryId(dto.getCategoryId());
        item.setPrice(dto.getPrice().setScale(2));
        item.setImages(toJson(dto.getImages()));
        item.setAiTags(toJson(review.tags()));
        item.setAiReviewed(true);
        item.setTradeLocation(dto.getTradeLocation().trim());
        item.setStatus("ON_SALE");
        item.setViewCount(0);
        item.setIsDeleted(false);
        itemMapper.insert(item);
        return marketplaceService.getSnapshot(item.getId(), publisherId);
    }

    private void validateImages(List<String> images) {
        for (String image : images) {
            if (!StringUtils.hasText(image) || !image.startsWith("/uploads/items/")) {
                throw new BusinessException(ResultCode.BAD_REQUEST, "图片地址必须来自平台上传接口");
            }
        }
    }

    private ReviewResult review(PublishItemDTO dto, Category category) {
        String text = (dto.getTitle() + " " + dto.getDescription()).toLowerCase(Locale.ROOT);
        for (String keyword : VIOLATION_KEYWORDS) {
            if (text.contains(keyword.toLowerCase(Locale.ROOT))) {
                return new ReviewResult(true, "内容包含平台禁止发布的信息：" + keyword, List.of());
            }
        }
        return new ReviewResult(false, "", generateTags(dto, category));
    }

    private List<String> generateTags(PublishItemDTO dto, Category category) {
        Set<String> tags = new LinkedHashSet<>();
        tags.add(category.getName());
        String text = dto.getTitle() + " " + dto.getDescription();
        addKnownTags(text, tags);
        for (String token : text.split("[\\s,，。.!！?？、/\\\\()（）\\[\\]【】]+")) {
            String value = token.trim();
            if (value.length() >= 2 && value.length() <= 16 && tags.size() < 6) {
                tags.add(value);
            }
        }
        tags.add(dto.getType().equals("SELL") ? "出售" : "求购");
        return new ArrayList<>(tags).stream().limit(6).toList();
    }

    private void addKnownTags(String text, Set<String> tags) {
        String normalized = text.toLowerCase(Locale.ROOT);
        List<String> candidates = List.of(
                "iPad", "苹果", "小米", "华为", "耳机", "键盘", "充电宝", "教材", "高数", "考研",
                "四级", "全新", "99新", "有笔记", "台灯", "风扇", "背包", "运动鞋", "篮球", "Switch"
        );
        for (String candidate : candidates) {
            if (normalized.contains(candidate.toLowerCase(Locale.ROOT)) && tags.size() < 6) {
                tags.add(candidate);
            }
        }
    }

    private void saveViolationReport(Long userId, PublishItemDTO dto, ReviewResult review, boolean aiReviewError) {
        ViolationReport report = new ViolationReport();
        report.setUserId(userId);
        report.setOriginalTitle(dto.getTitle());
        report.setOriginalDescription(dto.getDescription());
        report.setViolationType(aiReviewError ? "AI_REVIEW_ERROR" : "CONTENT_VIOLATION");
        report.setViolationReason(review.reason());
        report.setAiTags(toJson(review.tags()));
        report.setStatus("PENDING");
        report.setAiReviewError(aiReviewError);
        violationReportMapper.insert(report);
    }

    private String toJson(Object value) {
        try {
            return objectMapper.writeValueAsString(value);
        } catch (JsonProcessingException e) {
            throw new BusinessException(ResultCode.SERVER_ERROR, "JSON 序列化失败");
        }
    }

    private String extensionOf(String originalFilename, String contentType) {
        String ext = "";
        if (StringUtils.hasText(originalFilename) && originalFilename.contains(".")) {
            ext = originalFilename.substring(originalFilename.lastIndexOf('.') + 1).toLowerCase(Locale.ROOT);
        }
        if (!List.of("jpg", "jpeg", "png", "webp").contains(ext)) {
            if ("image/jpeg".equalsIgnoreCase(contentType)) ext = "jpg";
            else if ("image/png".equalsIgnoreCase(contentType)) ext = "png";
            else if ("image/webp".equalsIgnoreCase(contentType)) ext = "webp";
        }
        if (!List.of("jpg", "jpeg", "png", "webp").contains(ext)) {
            throw new BusinessException(ResultCode.BAD_REQUEST, "仅支持 jpg、png、webp 图片");
        }
        return "jpeg".equals(ext) ? "jpg" : ext;
    }

    private record ReviewResult(boolean violation, String reason, List<String> tags) {
    }
}
